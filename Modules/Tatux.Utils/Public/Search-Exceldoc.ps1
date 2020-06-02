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
		[string[]]$Query,
		[switch]
		$OnlyMatches
	)
	
	BEGIN {
		try {
			$application = New-Object -comobject excel.application -ErrorAction Stop
			$application.DisplayAlerts = $False
			$application.EnableEvents = $False
		}
		catch {
			Write-Error "Failed to load Excel Com Object, make sure Microsoft Excel is installed."
			break
		}
		$application.visible = $False
		
		$Props = [ordered]@{
			Name   = (Split-Path -Path $Path -Leaf)
			Type   = (Split-Path -Path $Path -Leaf).Split('.')[-1]
			Query  = 'N/A'
			Page   = 'N/A'
			Path   = $Path
			Match  = 'N/A'
			Result = ''
		}
	}
	PROCESS {
		# Open doc ready for searching
		try {
			$Workbooks = $application.Workbooks.open($Path, $false, $true)
		}
		catch {
			Write-Error "Failed to open $Path, Error: $($_.Exception.Message)"
			$Obj = New-Object PSObject -Property $Props
			$Obj.Result = "Failed-Document"
			break
		}
		$Sheets = $Workbooks.Sheets
		# Search for queried text
		

		foreach ($Q in $Query) {
			foreach ($a in $Sheets) {
				try {
					$QueryResults = $a.Cells.Find($Q)
				}
				catch {
					Write-Error "Failed to search document $Path. $($_.Exception.Message)"
					$Obj = New-Object PSObject -Property $Props
					$Obj.Query = $Q
					$Obj.Page = "Sheet: $($a.Name)"
					$Obj.Result = "Failed-Document"
					$Obj
					break
				}
				$Obj = New-Object PSObject -Property $Props
				$Obj.Query = $Q
				$Obj.Page = "Sheet: $($a.Name)"
				if ($QueryResults) {
					$Obj.Match = $true
					$Obj.Result = "Success"
					$Obj
					break
				}
				else {
					$Obj.Match = $false
					if ($OnlyMatches -eq $False) {
						$Obj.Result = "Success"
						$Obj
					}
				}
				if ($Obj.Result) {
					continue
				}
			}
		}
	}
	END {
		$Workbooks.Close($False)
		$application.quit()
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbooks) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($application) | Out-Null
		
		Remove-Variable -Name application
		
		[gc]::collect()
		
		[gc]::WaitForPendingFinalizers()
	}
}