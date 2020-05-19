<#
	.SYNOPSIS
		Searches a word document for desired test and outputs results
	
	.DESCRIPTION
		Using the Find function the the Word.Application Comobject this function searches for the enter text. It has multiple switch options to change the search behavior and returns an object with a properties determining if it matched or not
	
	.PARAMETER Path
		The path of the word doc you would like to search, use doc or docx.
	
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
		PS C:\> Search-WordDoc -Path $value1
	
	.OUTPUTS
		Object
	
	.NOTES
		Uses the Word.Application ComObject and thus needs office installed on the machine running the command.
#>
function Search-WordDoc {
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
				if ($_ -notmatch "(\.doc|\.docx)") {
					throw "The file specified in the path argument must be either of type xls or xlsx"
				}
				return $true
			})]
		[ValidateNotNullOrEmpty()]
		[string]$Path,
		[Parameter(ParameterSetName = 'Match')]
		[boolean]$MatchCase = $false,
		[Parameter(ParameterSetName = 'Match')]
		[boolean]$MatchWholeWord = $true,
		[Parameter(ParameterSetName = 'Match')]
		[boolean]$MatchSoundsLike = $false,
		[Parameter(ParameterSetName = 'Match')]
		[boolean]$MatchAllWordForms = $false,
		[Parameter(ParameterSetName = 'Match',
			Mandatory = $true)]
		[string[]]$Query,
		[Parameter(ParameterSetName = 'Match')]
		[boolean]$MatchWildCard,
		[switch]
		$OnlyMatches
	)
	
	BEGIN {
		try {
			$application = New-Object -comobject word.application
		}
		Catch {
			Write-Error "Failed to load Word Com Object, check Microsoft Word is installed."
			break
		}
		$application.visible = $False
		
		$forward = $true
		$wrap = 1
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
			$Document = $application.documents.open($Path, $true)
		}
		catch {
			Write-Error "Failed to open document $Path. Error: $($_.Exception.Message)"
			$Obj = New-Object PSObject -Property $Props
			$Obj.Result = "Failed-Document"
			break
		}
		$Range = $Document.content
		foreach ($Q in $Query) {
			# Search for queried text
			$null = $Range.movestart()
			try {
				$QueryResults = $Range.find.execute($Q, $MatchCase,
					$MatchWholeWord, $MatchWildCard, $MatchSoundsLike,
					$MatchAllWordForms, $forward, $wrap)
			}
			catch {
				Write-Error "Failed to search document $Path. $($_.Exception.Message)"
				$Obj = New-Object PSObject -Property $Props
				$Obj.Query = $Q
				$Obj.Result = "Failed-Document"
				$Obj
				break
			}
			$Obj = New-Object PSObject -Property $Props
			$Obj.Query = $Q
			if ($QueryResults) {
				$Obj.Match = $true
				$Obj.Result = "Success"
				$Obj
				break
			}
			else {
				if ($OnlyMatches -eq $false) {
					$Obj.Match = $false
					$Obj.Result = "Success"
					$Obj
				}
			}
		}
	}
	END {
		$document.close($false)
		$application.quit()
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Range) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Document) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($application) | Out-Null
		
		Remove-Variable -Name application
		
		[gc]::collect()
		
		[gc]::WaitForPendingFinalizers()
	}
}