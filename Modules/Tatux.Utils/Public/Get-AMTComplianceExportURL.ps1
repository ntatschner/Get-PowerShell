<#
	.SYNOPSIS
		Takes the output of Get-ComplianceSearchAction and pulls the result URL and SAS token out
	
	.DESCRIPTION
		From the property 'Results' the Cmdlet Get-ComplianceSearchAction produces this command pulls out from the sting the URL and SAS token so it can be utalised easily.
	
	.PARAMETER Results
		The returned object of Get-ComplianceSearchAction
	
	.EXAMPLE
		PS C:\> Get-AMTComplianceExportURL -Results $Results
	
	.OUTPUTS
		System.Management.Automation.PSObject
	
#>
function Get-AMTComplianceExportURL
{
	[CmdletBinding()]
	[OutputType([psobject])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateScript({
				if ([System.String]::isNullorEmpty($_.Results) -eq $true)
				{
					$false
					Throw "Make sure the input contains a none null results parameter."
				}
				else
				{
					$true
				}
			})]
		[System.Object]$Results
	)
	
	PROCESS
	{
		$URL = ($Results.results | Select-String -Pattern "(Container url: (.*?);)").Matches.Groups[2].Value
		$SASToken = ($Results.results | Select-String -Pattern "(SAS token: (.*?);)").Matches.Groups[2].Value
		
		$Props = [ordered]@{
			URL	     = $URL
			SASToken = $SASToken
			FullURL  = "$($URL)/$($SASToken)"
		}
		New-Object PSObject -Property $Props
	}
}