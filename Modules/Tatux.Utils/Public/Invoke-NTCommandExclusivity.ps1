<#
	.SYNOPSIS
		Locks passed scriptblock until it's finished processing
	
	.DESCRIPTION
		The function locks the passed scriptblock for exclusive access until all of the command is complete, this is useful when you want to write to a file and have concurrent file attempt which could result in the file being in use and to command failing during the parent command.
	
	.PARAMETER Name
		The Name of the Action you are performing, This is used as the MuteX Name.
	
	.PARAMETER ScriptBlock
		The script block of the command you want to lock
	
	.PARAMETER Global
		Specifies if the MuteX will be made available to all system threads.
	
	.PARAMETER InputObject
		Objects to pass from the global scope
	
	.EXAMPLE
		PS C:\> Invoke-NTCommandExclusivity -Name 'Value1' -ScriptBlock $value2
	
	.NOTES
		www.tatux.co.uk
#>
function Invoke-NTCommandExclusivity
{
	[CmdletBinding()]
	[OutputType([System.Object])]
	param
	(
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Enter the name for the action you are performing to help identify it, keep it unique.')]
		[ValidateLength(3, 50)]
		[System.String]$Name,
		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,
		[Switch]$Global
	)
	
	Begin
	{
		Write-Verbose "Instantiating the MuteX Object Based on the Global Switch Parameter."
		If ($Global)
		{
			Write-Verbose "The Global Switch Paramiter was set to True, creating a Global MuteX Object."
			$MuteX = New-Object System.Threading.Mutex($false, "Global\$Name")
		}
		Else
		{
			Write-Verbose "The Global Switch Paramiter was not used and is set to False by default, creating MuteX Object."
			$MuteX = New-Object System.Threading.Mutex($false, $Name)
		}
	}
	Process
	{
		Write-Verbose "Claming MuteX Process and blocking other claimants"
		$MuteX.WaitOne() | Out-Null
		Write-Verbose "Starting ScriptBlock execution"
		Invoke-Command -ScriptBlock $ScriptBlock
		Write-Verbose "Execution complete, releasing process lock."
		$MuteX.ReleaseMutex()
	}
	End
	{
		Write-Verbose "Closing out MuteX"
		$MuteX.Close()
	}
}
