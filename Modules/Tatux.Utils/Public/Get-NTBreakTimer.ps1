<#
	.SYNOPSIS
		Mn time based parameter entry this function produces a bool output
	
	.DESCRIPTION
		Used to break from loops/control scripts based on a time value and outputs Bool
		
		True not inside defined timings
		False outside of defined timings
	
	.PARAMETER DateTime
		The Date and Time the command should stop running
	
	.PARAMETER StartTime
		Start time the command starts returning true
	
	.PARAMETER EndTime
		The time the command stop returning true
	
	.PARAMETER Time
		After this time the command returns false
	
	.EXAMPLE
		PS C:\> Get-BreakTimer
	
	.OUTPUTS
		boolean
	
	.NOTES
		Additional information about the function.
#>
function Get-NTBreakTimer
{
	[CmdletBinding(DefaultParameterSetName = 'Specific')]
	[OutputType([boolean], ParameterSetName = 'Specific')]
	[OutputType([boolean], ParameterSetName = 'Range')]
	[OutputType([boolean], ParameterSetName = 'Time')]
	param
	(
		[Parameter(ParameterSetName = 'Specific')]
		[string]$DateTime,
		[Parameter(ParameterSetName = 'Range')]
		[int]$StartTime,
		[Parameter(ParameterSetName = 'Range')]
		[int]$EndTime,
		[Parameter(ParameterSetName = 'Time')]
		[int]$Time
	)
	
	switch ($PsCmdlet.ParameterSetName)
	{
		'Specific' {
			# parse input to determine datetime
			Try
			{
				$DateTime = [datetime]::Parse($DateTime)
			}
			Catch
			{
				Write-Error "Could not validate date time entered, try in the DD/MM/YYYY HH:MM format."
			}
			# return results
			if ($DateTime -gt (Get-Date))
			{
				$true
			}
			else
			{
				$false
			}
			break
		}
		'Range' {
			# Validate start and end time
			if ($StartTime -match "\d{1,2}:\d{1,2}(:\d{1,2})?")
			{
				try
				{
					$StartTime = [datetime]::Parse($StartTime)
				}
				Catch
				{
					Write-Error "Could not validate start time entered, try in the DD/MM/YYYY HH:MM format."
					break
				}
				try
				{
					$EndTime = [datetime]::Parse($EndTime)
				}
				Catch
				{
					Write-Error "Could not validate end time entered, try in the DD/MM/YYYY HH:MM format."
					break
				}
			}
			elseif ($StartTime -match "\d{1,2}\/\d{1,2}\/\d{2,4}\s\d{1,2}(:\d{1,2})?")
			{
				
			}
			
			break
		}
		'Time' {
			#TODO: Place script here
			break
		}
	}
}
