<#
	.SYNOPSIS
		Searches a word document for desired test and outputs results
	
	.DESCRIPTION
		A detailed description of the Search-WordDoc function.
	
	.PARAMETER Path
		Enter the path of the file you'd like to search
	
	.PARAMETER MatchCase
		A description of the MatchCase parameter.
	
	.PARAMETER MatchWholeWord
		A description of the MatchWholeWord parameter.
	
	.PARAMETER MatchSoundsLike
		A description of the MatchSoundsLike parameter.
	
	.PARAMETER MatchAllWordForms
		A description of the MatchAllWordForms parameter.
	
	.PARAMETER Query
		A description of the Query parameter.
	
	.PARAMETER MatchWildCard
		A description of the MatchWildCard parameter.
	
	.EXAMPLE
		PS C:\> Search-WordDoc -Path $value1
	
	.OUTPUTS
		boolean, string
	
	.NOTES
		Additional information about the function.
#>
function Search-WordDoc
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
				if ($_ -notmatch "(\.doci|\.docx)")
				{
					throw "The file specified in the path argument must be either of type msi or exe"
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
		[Parameter(ParameterSetName = 'Match')]
		[string]$Query,
		[Parameter(ParameterSetName = 'Match')]
		[boolean]$MatchWildCard
	)
	
	BEGIN
	{
		$application = New-Object -comobject word.application
		$application.visible = $False
		
		$forward = $true
		$wrap = 1
		
	}
	PROCESS
	{
		# Open doc ready for searching
		$Document = $application.documents.open($Path)
		$Range = $Document.content
		$null = $Range.movestart()
		
		# Search for queried text
		
		$QueryResults = $Range.find.execute($Query, $MatchCase,
			$MatchWholeWord, $MatchWildCard, $MatchSoundsLike,
			$MatchAllWordForms, $forward, $wrap)
		
		$Props = [ordered]@{
			Name = (Split-Path -Path $Path -Leaf)
			Path = $Path
			Match = $QueryResults -as [bool]
		}
		$Obj = New-Object PSObject -Property $Props
		
		if ($QueryResults)
		{
			Write-Output $Obj
		}
		else
		{
			Write-Verbose "Query didn't find anything for $Path"
			Write-Output $Obj
		}
	}
	END
	{
		$document.close()
		$application.quit()
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Range) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Document) | Out-Null
		
		[System.Runtime.InteropServices.Marshal]::ReleaseComObject($application) | Out-Null
		
		Remove-Variable -Name application
		
		[gc]::collect()
		
		[gc]::WaitForPendingFinalizers()
	}
}