<#
	.SYNOPSIS
		Searches a Excel document for desired test and outputs results
	
	.DESCRIPTION
		Using the Find function the the Excel.Application Comobject this function searches for the enter text. It has multiple switch options to change the search behavior and returns an object with a properties determining if it matched or not
	
	.PARAMETER Path
		The path of the word doc you would like to search, use xls or xlsx.
	
	.PARAMETER MatchCase
		Match the case of the entered string exactly.
	
	.PARAMETER MatchWholeWord
		Only match a whole word and not matches inside words.
	
	.PARAMETER MatchSoundsLike
		Matches on text that sounds like the entered text, ie. write, riot.
	
	.PARAMETER MatchAllWordForms
		Matches on forms of the entered string, i.e color, colour.
	
	.PARAMETER Query
		The string to search for.
	
	.PARAMETER MatchWildCard
		Matches any wild card character entered in the string, ie. *.
	
	.EXAMPLE
		PS C:\> Search-ExcelDoc -Path $value1
	
	.OUTPUTS
		Object
	
	.NOTES
		Uses the Word.Application ComObject and thus needs office installed on the machine running the command.
#>
function Search-ExcelDoc
{
	[CmdletBinding(DefaultParameterSetName = 'Match')]
	[OutputType([string], ParameterSetName = 'Match')]
	param
	(
		[Parameter(ParameterSetName = 'Match',
				   Mandatory = $true)]
		[ValidateScript({
				if (-Not ($_ | Test-Path))
				{
					throw "File or folder does not exist"
				}
				if (-Not ($_ | Test-Path -PathType Leaf))
				{
					throw "The Path argument must be a file. Folder paths are not allowed."
				}
				if ($_ -notmatch "(\.xls|\.xlsx)")
				{
					throw "The file specified in the path argument must be either of type xls or xlsx"
				}
				return $true
			})]
		[ValidateNotNullOrEmpty()]
		[string]$Path,
		[string]$Query
	)
	
	BEGIN
	{
		$application = New-Object -comobject excel.application
		$application.visible = $False
		
	}
	PROCESS
	{
		# Open doc ready for searching
		$Workbooks = $application.Workbooks.open($Path)
		$Sheets = $Workbooks.Sheets
		
		# Search for queried text
		
		foreach ($a in $Sheets) {
			$QueryResults = $a.Cells.Find($Query)
			$Props = [ordered]@{
				Name = (Split-Path -Path $Path -Leaf)
				Path = $Path
				Match = $QueryResults -as [bool]
			}
			$Obj = New-Object PSObject -Property $Props

			if ($QueryResults) {
				$Obj
				break
			}
		}
	}
	END
	{
		$application.quit()
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbooks) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($application) | Out-Null
		
		Remove-Variable -Name application
		
		[gc]::collect()
		
		[gc]::WaitForPendingFinalizers()
	}
}