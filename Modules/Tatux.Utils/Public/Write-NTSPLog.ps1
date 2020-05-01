<#
	.SYNOPSIS
		Logs the specified information to SharePoint lists
	
	.DESCRIPTION
		This function writes the supplied parameter values to 2 SharePoint lists,
		one being an overview of the script or automation this function is used in,
		the other a log for each action.
		
		If the lists don't exist, the function can create them and if they exist but are missing some fields it will add them.
		
		Overview List;
		The Fields(Columns) in the Overview list have the following passed from the parameters:
		"ProcessName", "CurrentStatus", "Result", "ProcessOwner", "ProcessObjectCount", "ProcessObjectCurrentItem"
		In addition, "RunBy", "HostSystem" are added automatically.
		
		This is where you can see each process the function used in and its current status.
		The initial run of this function in a process should have the -PassThru switch used and captured (In a variable),
		this will allow you to reference the integer further down the logging using the -ID parameter so that the items added to the Logs list match up with the Overview list.
		
		Log List;
		The Fields(Columns) in the Log list have the following passed from the parameters;
		"ProcessName", "CurrentStatus", "Result", "ProcessOwner", "ProcessObjectCount", "ProcessObjectCurrentItem", "TargetObject", "CommandRun", "OverviewReferenceId"
		In addition, "RunBy", "HostSystem" are added automatically.
		
		For each list a default view is created however remember that there is a limit of what you can view in a list on screen,
		make sure to create some kind of reporting or live PowerBI dashboard to display the date in a meaningful way.
	
	.PARAMETER OverviewList
		Enter the name of overview list, will create a new one if none exists in the current connection
	
	.PARAMETER LogList
		Enter the name of log list, will create a new one if none exists in the current connection
	
	.PARAMETER Passthru
		This outputs an object with the ID of the Overview List item
	
	.PARAMETER SkipCheck
		Specify this switch to skip checking if the Lists and Fields exist, should speed up process slightly.
	
	.PARAMETER PreBuildLists
		Builds named lists if missing and missing fields without adding or amending the lists
	
	.PARAMETER ProcessName
		Name of the Script or function this function is used inside of, can be left blank and 'Get-PSCallStack' will be used.
	
	.PARAMETER CurrentStatus
		The state of the current process
	
	.PARAMETER Result
		The result of the command or activity
	
	.PARAMETER ProcessOwner
		Who created the process this function logs
	
	.PARAMETER ProcessObjectCount
		Count of the items processing
	
	.PARAMETER ProcessObjectCurrentItem
		The current item in the process
	
	.PARAMETER TargetObject
		Target of the command i.e. user
	
	.PARAMETER CommandRun
		What Command is run
	
	.PARAMETER Id
		Only pass to this parameter after the first instance of the function in your script as it will act as a hook as to what item in the Overview List the Log List item belongs too,
		this will allow you to reference the 2 in some reporting. i.e. PowerBI.
	
	.PARAMETER Errors
		Any errors generated can be added here

	.PARAMETER Step
		Current Step in the Process

	.PARAMETER Notes
		Any notes for this item
	
	.EXAMPLE
		This function is to be used in other automation processes to log their output to SharePoint Lists.
		
		Small example of how this would look;
		
		# My Script That does things
		
		$OverViewLoggingList = Write-NTSPLog -OverviewList "My Logging Overview" -LogList "My Logging Logs" -PassThru `
		-ProcessName "Process Named Doing Things" -CurrentStatus Starting -Result Success -ProcessOwner "Me" `
		-TargetObject "A List of Users" -CommandRun "Starting Process"
		
		$AllTheUsers = Get-AllTheUsers -AllOfThem
		$Counting = 0
		foreach ($a in $AllTheUsers) {
		$Counting++
		Try
		{
		Awesome-PowerShellCommand -ImAParameter $a -ErrorAction 'Stop'
		Write-NTSPLog -OverviewList "My Logging Overview" -LogList "My Logging Logs" `
		-ProcessName "Process Named Doing Things" -CurrentStatus InProgress -Result Success -ProcessOwner "Me" `
		-TargetObject $a -CommandRun "I ran this one : 'Awesome-PowerShellCommand -ImAParameter $a -ErrorAction 'Stop''" `
		-ProcessObjectCount $AllTheUsers -ProcessObjectCurrentItem $Counting -ID $OverViewLoggingList
		}
		Catch
		{
		Write-NTSPLog -OverviewList "My Logging Overview" -LogList "My Logging Logs" `
		-ProcessName "Process Named Doing Things" -CurrentStatus InProgress -Result Failure -ProcessOwner "Me" `
		-TargetObject $a -CommandRun "I ran this one : 'Awesome-PowerShellCommand -ImAParameter $a -ErrorAction 'Stop''" `
		-ProcessObjectCount $AllTheUsers -ProcessObjectCurrentItem $Counting -ID $OverViewLoggingList -Errors $_.Exception.Message
		}
	
	.OUTPUTS
		void, System.String
#>
#Requires -Version 3.0
function Write-NTSPLog
{
	[CmdletBinding(DefaultParameterSetName = 'Build',
				   ConfirmImpact = 'High',
				   SupportsShouldProcess = $true)]
	[OutputType([System.String], ParameterSetName = 'Build')]
	[OutputType([void], ParameterSetName = 'Skip')]
	[OutputType([System.String])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0,
				   HelpMessage = 'Enter the name of overview list, will create a new one if none exists in the current connection')]
		[ValidateNotNullOrEmpty()]
		[System.String]$OverviewList,
		
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$LogList,
		
		[Parameter(ParameterSetName = 'Build')]
		[switch]$Passthru,
		
		[Parameter(ParameterSetName = 'Skip')]
		[switch]$SkipCheck,
		
		[Parameter(ParameterSetName = 'Build')]
		[switch]$PreBuildLists,
		
		[System.String]$ProcessName,
		
		[System.String]$Step,
		
		[ValidateSet('Starting', 'InProgress', 'Completed')]
		[System.String]$CurrentStatus,
		
		[ValidateSet('Failure', 'Warning', 'Success-Warning', 'Success')]
		[System.String]$Result,
		
		[System.String]$ProcessOwner,
		
		[int32]$ProcessObjectCount,
		
		[int32]$ProcessObjectCurrentItem,
		
		[System.String]$TargetObject,
		
		[System.String]$CommandRun,
		
		[int64]$ID,
		
		[System.String]$Errors,
		
		[System.String]$Notes
	)
	
	BEGIN
	{
		# Embedded Functions Start		
		#region	Modules		
		
		try {
			Get-Module -Name SharePointPnPPowerShellOnline -ErrorAction Stop
		} Catch {
			Write-Error "Module: SharePointPnPPowerShellOnline not found"
			break
		}

		function ConvertTo-CapitalSplit
		{
			param
			(
				[Parameter(Mandatory = $true)]
				[System.String]$InputString
			)
			
			$OutputString = @()
			foreach ($a in ($InputString.ToCharArray()))
			{
				if ([char]::IsUpper($a))
				{
					$OutputString += " " + $a
				}
				else
				{
					$OutputString += $a
				}
			}
			return ($OutputString -Join '').Trim()
		}
		
		#endregion		
		# Embedded Functions End
		
		# Global Vars Start
		#region
		
		# List of internal names for the fields(Columns) in SharePoint, when adding more make sure to CAPITALIZE the start of a new word to have it split to the displayname
		$OverviewFieldsInternalName = "ProcessName", "Step", "CurrentStatus", "Result", "ProcessOwner", "ProcessObjectCount", "ProcessObjectCurrentItem", "RunBy", "HostSystem", "ConnectedWithAccount", "Errors", "Notes"
		# List of internal names for the fields(Columns) in SharePoint, when adding more make sure to CAPITALIZE the start of a new word to have it split to the displayname
		$LogFieldsInternalName = "ProcessName", "Step", "CurrentStatus", "Result", "ProcessOwner", "ProcessObjectCount", "ProcessObjectCurrentItem", "TargetObject", "CommandRun", "OverviewReferenceId", "RunBy", "HostSystem", "ConnectedWithAccount", "Errors", "Notes"
		# List of Bound Parameters it's ignoring.
		# Overview List
		$OverviewNotChecking = "LocalLogPath", "SkipCheck", "ID", "PassThru", "ErrorAction", "WarningAction", "Verbose", "ErrorVariable", "WarningVariable", "OutVariable", "OutBuffer", "Debug", "Confirm", "LogList", "OverviewList", "TargetObject", "CommandRun"
		# Log List
		$LogNotChecking = "LocalLogPath", "SkipCheck", "ID", "PassThru", "ErrorAction", "WarningAction", "Verbose", "ErrorVariable", "WarningVariable", "OutVariable", "OutBuffer", "Debug", "Confirm", "LogList", "OverviewList"
		#endregion
		# Global Vars End
		
		# Module Import Start
		#region
		try
		{
			Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop -Verbose:$false -DisableNameChecking
		}
		catch
		{
			Write-Error -Message "Could not import required module SharePointPnPPowerShellOnline, try installing and running again."
			break
		}
		#endregion	
		#Module Import End
		
		#region Lists
		if ($SkipCheck -eq $false)
		{
			# Overview List Start
			#region
			# This generates the status of the running script and and privides a unique ID to correlate between Overview list and logging list items
			
			# Overview variables
			$ConnectedSite = Get-PnpSite | Select-Object -ExpandProperty url
			$OverviewFields = @()
			
			foreach ($a in $OverviewFieldsInternalName)
			{
				$OverviewFields += @{
					'InternalName' = $a;
					'DisplayName'  = (ConvertTo-CapitalSplit -InputString $a)
				}
			}
			# Adding From Default Field Items
			$OverviewFields += @{
				'InternalName' = "_DCDateModified";
				'DisplayName'  = "Date Modified"
			}
			# Looking for referenced Overview list
			try
			{
				Write-Verbose "Testing if $($OverviewList) exists"
				$Global:OverviewListObject = Get-PnPList -Identity $OverviewList -throwExceptionIfListNotFound -ErrorAction Stop
				Write-Verbose "Overview List $($OverviewList) found, moving on.."
				Write-Verbose "Checking if required fields are present.."
				# Checking existing overview list fields - start
				# Gets all the fields in the view
				$OverviewListFields = Get-PnPField -List $OverviewListObject.Title
				# Compares fields currently in the view with the ones we've specifed
				$OverviewCompare = Compare-Object -ReferenceObject $OverviewListFields.internalname -DifferenceObject $OverviewFieldsInternalName | Where-Object SideIndicator -EQ '=>'
				if (([System.String]::IsNullOrEmpty($OverviewCompare) -eq $false) -or ($OverviewCompare.count -ge 0))
				{
					Write-Verbose "Found missing Fields"
					foreach ($a in $OverviewCompare.inputobject)
					{
						Write-Verbose "Missing field $($a)"
						if ($PSCmdlet.ShouldProcess("Adding missing Field '$($a)'"))
						{
							try
							{
								Write-Verbose "Adding missing Field $($a)"
								$null = Add-PnPField -List $OverviewListObject.Title -InternalName $a -DisplayName $(ConvertTo-CapitalSplit -InputString $a) -Type Text -AddToDefaultView:$true -ErrorAction Stop
							}
							catch
							{
								Write-Error -Message 'Failed to add missing Field, breaking..'
								break
							}
						}
					}
				}
				else
				{
					Write-Verbose "All Fields present"
				}
				Write-Verbose "Pre-flight checks complete"
				# Checking existing overview list fields - end
			}
			catch [InvalidOperationException]
			{
				Write-Verbose "Failed to connect, breaking.."
				break
			}
			catch
			{
				Write-Verbose "Could not find Overview list : $($OverviewList)"
				try
				{
					Write-Verbose "Creating List : $($OverviewList)"
					if ($PSCmdlet.ShouldProcess("Create new Overview List '$($OverviewList)'`nin the site $($ConnectedSite)"))
					{
						$null = New-PnPList -Title $OverviewList -Template 100 -ErrorAction 'Stop'
						$Global:OverviewListObject = Get-PnPList -Identity $OverviewList -ErrorAction Stop
					}
					else
					{
						Break
					}
					Write-Verbose "Overview List $($OverviewList) created.."
				}
				catch
				{
					Write-Verbose "Failed to create Overview list : $($OverviewList), breaking.."
					Write-Error -Message $($_.Exception.Message)
					break
				}
				
				# Creating Fields and setting default values
				# Default Field Value = Required
				try
				{
					# Modifying default value
					Write-Verbose "Setting default field 'Title' to not required"
					# Setting default field Title to not required.
					$null = Set-PnPField -List $OverviewListObject.Title -Identity "Title" -Values @{ "Required" = $false }
				}
				Catch
				{
					Write-Error -Message 'Failed to set the dafault value of "Title", breaking..'
					break
				}
				# Adding Required Fields
				foreach ($Field in $OverviewFields)
				{
					try
					{
						$null = Add-PnPField -List $OverviewListObject.Title @Field -Type Text -ErrorAction Stop
					}
					Catch
					{
						Write-Error -Message "Failed to add Overview List Field $($Field.InternalName), breaking.."
						break
					}
				}
				# Creating default view
				try
				{
					# Creating View
					Write-Verbose "Creating Default View"
					$OverviewFieldsInternalName += "_DCDateModified"
					$null = Add-PnPView -List $OverviewListObject.Title -Title $($OverviewListObject.Title + " Default View") -SetAsDefault -Fields $OverviewFieldsInternalName -RowLimit 5000 -ErrorAction Stop
				}
				Catch
				{
					Write-Error -Message $($_.Exception.Message)
					Write-Error -Message 'Failed to set Overview List default Field values, breaking..'
					break
				}
			}
			#endregion
			# Overview List End
			
			# Log List Start
			#region
			
			# Log List variables
			$LogFields = @()
			
			foreach ($a in $LogFieldsInternalName)
			{
				$LogFields += @{
					'InternalName' = $a;
					'DisplayName'  = (ConvertTo-CapitalSplit -InputString $a)
				}
			}
			# Adding From Default Field Items
			$LogFields += @{
				'InternalName' = "_DCDateModified";
				'DisplayName'  = "Date Modified"
			}
			# Looking for referenced Log list
			try
			{
				Write-Verbose "Testing if $($LogList) exists"
				$Global:LogListObject = Get-PnPList -Identity $LogList -throwExceptionIfListNotFound -ErrorAction Stop
				Write-Verbose "Log List $($LogList) found, moving on.."
				Write-Verbose "Checking if required fields are present.."
				# Checking existing Log list fields - start
				# Gets all the fields in the view
				$LogListFields = Get-PnPField -List $LogListObject.Title
				# Compares fields currently in the view with the ones we've specifed
				$LogCompare = Compare-Object -ReferenceObject $LogListFields.internalname -DifferenceObject $LogFieldsInternalName | Where-Object SideIndicator -EQ '=>'
				
				if (([System.String]::IsNullOrEmpty($LogCompare) -eq $false) -or ($LogCompare.count -ge 0))
				{
					Write-Verbose "Found missing Fields"
					foreach ($a in $LogCompare.inputobject)
					{
						Write-Verbose "Missing field $($a)"
						if ($PSCmdlet.ShouldProcess("Adding missing Field '$($a)'"))
						{
							try
							{
								Write-Verbose "Adding missing Field $($a)"
								$null = Add-PnPField -List $LogListObject.Title -InternalName $a -DisplayName $(ConvertTo-CapitalSplit -InputString $a) -Type Text -AddToDefaultView:$true -ErrorAction Stop
							}
							catch
							{
								Write-Error -Message 'Failed to add missing Field, breaking..'
								break
							}
						}
					}
				}
				else
				{
					Write-Verbose "All Fields present"
				}
				Write-Verbose "Pre-flight checks complete"
				# Checking existing Log list fields - end
			}
			catch [InvalidOperationException]
			{
				Write-Verbose "Failed to connect, breaking.."
				break
			}
			catch
			{
				Write-Verbose "Could not find Log list : $($LogList)"
				try
				{
					Write-Verbose "Creating List : $($LogList)"
					if ($PSCmdlet.ShouldProcess("Create new Log List '$($LogList)'`nin the site $($ConnectedSite)"))
					{
						$Null= New-PnPList -Title $LogList -Template 100 -ErrorAction 'Stop' | Out-Null
						$Global:LogListObject = Get-PnPList -Identity $LogList -ErrorAction Stop
					}
					else
					{
						Break
					}
					Write-Verbose "Log List $($LogList) created.."
				}
				catch
				{
					Write-Verbose "Failed to create Overview list : $($LogList), breaking.."
					Write-Error -Message $($_.Exception.Message)
					break
				}
				
				# Creating Fields and setting default values
				# Default Field Value = Required
				try
				{
					# Modifying default value
					Write-Verbose "Setting default field 'Title' to not required"
					# Setting default field Title to not required.
					$null = Set-PnPField -List $LogListObject.Title -Identity "Title" -Values @{ "Required" = $false }
				}
				Catch
				{
					Write-Error -Message $($_.Exception.Message)
					Write-Error -Message 'Failed to set the dafault value of "Title", breaking..'
					break
				}
				# Adding Required Fields
				foreach ($Field in $LogFields)
				{
					try
					{
						$null = Add-PnPField -List $LogListObject.Title @Field -Type Text -ErrorAction Stop
					}
					Catch
					{
						Write-Error -Message "Failed to add Overview List Field $($Field.InternalName), breaking.."
						break
					}
				}
				# Creating default view
				try
				{
					# Creating View
					Write-Verbose "Creating Default View"
					$LogFieldsInternalName += "_DCDateModified"
					$null = Add-PnPView -List $LogListObject.Title -Title $($LogListObject.Title + " Default View") -SetAsDefault -Fields $LogFieldsInternalName -RowLimit 5000 -ErrorAction Stop
					Write-Verbose "Default View Created"
				}
				Catch
				{
					Write-Error -Message $($_.Exception.Message)
					Write-Error -Message 'Failed to set Log List default Field values, breaking..'
					break
				}
			}
			#endregion
			# Log List - End
			Write-Verbose "All pre-checks complete"
		}
		#endregion
	}
	PROCESS
	{
		if ($PreBuildLists -eq $false)
		{
			# Building output to each list - Start
			$CreationTimeStamp = Get-Date
			$ConnectionMadeBy = (Get-PnPConnection).PSCredential.UserName
			# Overview List - Start
			
			# Get non blank parameters that are not part of not checking list		
			$OverviewBoundParamsCompare = Compare-Object -ReferenceObject $($PSBoundParameters.Keys) -DifferenceObject $OverviewNotChecking | Where-Object SideIndicator -EQ '<='
			# Adding the selected parameters in to an HashTable
			$OverviewOutputItems = New-Object System.Collections.Hashtable
			foreach ($a in $OverviewBoundParamsCompare)
			{
				$item = @{
					$($a.InputObject) = $PSBoundParameters.Item($a.InputObject)
				}
				$OverviewOutputItems += $item
			}
			# Adding Default static Field items 
			$OverviewOutputItems += @{ "ConnectedWithAccount" = $ConnectionMadeBy; "RunBy" = $env:USERNAME; "HostSystem" = $env:COMPUTERNAME; "_DCDateModified" = $CreationTimeStamp }
			# Finally adding the paramter values to the Overview SharePoint List
			if (($PSBoundParameters.Keys -contains "ID") -eq $false)
			{
				try
				{
					Write-Verbose "Adding/Updating the Overview List"
					$Global:IDOutput = Add-PnPListItem -List $PSBoundParameters.Item("OverviewList") -Values $OverviewOutputItems -ErrorAction Stop
					if ([System.String]::IsNullOrEmpty($IDOutput))
					{
						Write-Error -Message "List Item not created, have you build the Lists?`nRemove -SkipCheck and try again, this will build the list for you." -Category InvalidOperation
						break
					}
					Write-Verbose "Added to the Overview List successfully"
					if ($Passthru)
					{
						$IDOutput | Select-Object -ExpandProperty id
					}
				}
				catch
				{
					Write-Error -Message "$($_.Exception.Message)"
				}
			}
			else
			{
				try
				{
					Write-Verbose "Adding/Updating the Overview List"
					$Null = Set-PnPListItem -Identity $PSBoundParameters.Item("ID") -List $PSBoundParameters.Item("OverviewList") -Values $OverviewOutputItems -SystemUpdate -ErrorAction Stop
					if ([System.String]::IsNullOrEmpty($IDOutput))
					{
						Write-Error -Message "List Item not created, have you build the Lists?`nRemove -SkipCheck and try again, this will build the list for you." -Category InvalidOperation
						break
					}
					Write-Verbose "Added to the Overview List successfully"
					if ($Passthru)
					{
						$IDOutput | Select-Object -ExpandProperty id
					}
				}
				catch
				{
					Write-Error -Message "$($_.Exception.Message)"
					break
				}
			}
			# Overview List -End
			# Log List - Start
			
			# Get none blank parameters that are not part of not checking list
			
			$LogBoundParamsCompare = Compare-Object -ReferenceObject $($PSBoundParameters.Keys) -DifferenceObject $LogNotChecking | Where-Object SideIndicator -EQ '<='
			# Adding the selected parameters in to an Hashtable
			$LogOutputItems = New-Object System.Collections.Hashtable
			foreach ($a in $LogBoundParamsCompare)
			{
				$item = @{
					$($a.InputObject) = $PSBoundParameters.Item($a.InputObject)
				}
				$LogOutputItems += $item
			}
			# Adding Default static Field items 
			$LogOutputItems += @{ "ConnectedWithAccount" = $ConnectionMadeBy; "RunBy" = $env:USERNAME; "HostSystem" = $env:COMPUTERNAME; "_DCDateModified" = $CreationTimeStamp }
			# Finally adding the paramter values to the Log SharePoint List
			if (($PSBoundParameters.Keys -contains "ID") -eq $false)
			{
				try
				{
					Write-Verbose "Adding to the Log List"
					$LogOutputItems += @{ "OverviewReferenceId" = $IDOutput.ID }
					$LogListCheck = Add-PnPListItem -List $PSBoundParameters.Item("LogList") -Values $LogOutputItems -ErrorAction Stop
					if ([System.String]::IsNullOrEmpty($LogListCheck))
					{
						Write-Error -Message "List Item not created, have you build the Lists?`nRemove -SkipCheck and try again, this will build the list for you." -Category InvalidOperation
						break
					}
					Write-Verbose "Added to the Log List successfully"
				}
				catch
				{
					Write-Error -Message "$($_.Exception.Message)"
				}
			}
			else
			{
				try
				{
					Write-Verbose "Adding to the Log List"
					$LogOutputItems += @{ "OverviewReferenceId" = $($PSBoundParameters.Item("ID")) }
					$LogListCheck = Add-PnPListItem -List $PSBoundParameters.Item("LogList") -Values $LogOutputItems -ErrorAction Stop
					if ([System.String]::IsNullOrEmpty($LogListCheck))
					{
						Write-Error -Message "List Item not created, have you build the Lists?`nRemove -SkipCheck and try again, this will build the list for you." -Category InvalidOperation
						break
					}
					Write-Verbose "Added to the Log List successfully"
				}
				catch
				{
					Write-Error -Message "$($_.Exception.Message)"
					break
				}
			}
			#Log List - End
			# Building output to each list - End
		}
	}
	END
	{
		
	}
}