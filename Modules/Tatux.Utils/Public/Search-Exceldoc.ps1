<#
	.SYNOPSIS
		Searches a Excel document for desired test and outputs results
	
	.DESCRIPTION
		Using the Find function the the Excel.Application Comobject this function searches for the enter text. It has multiple switch options to change the search behavior and returns an object with a properties determining if it matched or not
	
	.PARAMETER Path
		The path of the word doc you would like to search, use xls or xlsx.
	
	.PARAMETER Query
		The string to search for.
	
	.EXAMPLE
		PS C:\> Search-ExcelDoc -Path $value1
	
	.OUTPUTS
		Object
	
	.NOTES
		Uses the Word.Application ComObject and thus needs office installed on the machine running the command.
#>
function Search-ExcelDoc {
	[CmdletBinding(DefaultParameterSetName = 'Match')]
	[OutputType([string], ParameterSetName = 'Match')]
	param
	(
		[Parameter(ParameterSetName = 'Match',
			Mandatory = $true)]
		[ValidateScript( {
				if (-Not ($_ | Test-Path)) {
					throw "File or folder does not exist"
				}
				if (-Not ($_ | Test-Path -PathType Leaf)) {
					throw "The Path argument must be a file. Folder paths are not allowed."
				}
				if ($_ -notmatch "(\.xls|\.xlsx|\.xlsm)") {
					throw "The file specified in the path argument must be either of type xls, xlsx or xlsm"
				}
				return $true
			})]
		[ValidateNotNullOrEmpty()]
		[string]$Path,
		[string[]]$Query
	)
	
	BEGIN {
		$application = New-Object -comobject excel.application
		$application.visible = $False
		
	}
	PROCESS {
		# Open doc ready for searching
		$Workbooks = $application.Workbooks.open($Path)
		$Sheets = $Workbooks.Sheets
		
		# Search for queried text
		
		foreach ($a in $Sheets) {
			foreach ($Q in $Query) {
				$QueryResults = $a.Cells.Find($Q)
				$Props = [ordered]@{
					Name  = (Split-Path -Path $Path -Leaf)
					Query = $Q
					Path  = $Path
					Match = $QueryResults -as [bool]
				}
				$Obj = New-Object PSObject -Property $Props

				if ($QueryResults) {
					$Obj
					break
				}
			}
		}
	}
	END {
		$application.quit()
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbooks) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($application) | Out-Null
		
		Remove-Variable -Name application
		
		[gc]::collect()
		
		[gc]::WaitForPendingFinalizers()
	}
}