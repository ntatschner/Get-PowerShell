[cmdletBinding()]
Param(
 $Path
)

$matchCase = $false
$matchWholeWord = $true
$matchWildCards = $false
$matchSoundsLike = $false
$matchAllWordForms = $false
$forward = $true
$wrap = 1
$application = New-Object -comobject word.application
$application.visible = $False
$docs = Get-childitem -path $Path -Recurse -Include HSG*.docx,WES*.docx |
  where {$_.LastWriteTime -gt [datetime]"7/1/11" -AND $_.lastwritetime -le [datetime]"6/30/12"}
$findText = "guest blogger"
$i = 1
$totalwords = 0
$totaldocs = 0
Foreach ($doc in $docs)
{
 Write-Progress -Activity "Processing files" -status "Processing $($doc.FullName)" -PercentComplete ($i /$docs.Count * 100) 
 $document = $application.documents.open($doc.FullName)
 $range = $document.content
 $null = $range.movestart()
 $wordFound = $range.find.execute($findText,$matchCase,
  $matchWholeWord,$matchWildCards,$matchSoundsLike,
  $matchAllWordForms,$forward,$wrap)
  if($wordFound) 
    { 
     $doc.fullname
     $document.Words.count
     $totaldocs ++
     $totalwords += $document.Words.count
    } #end if $wordFound
 $document.close()
 $i++
} #end foreach $doc
$application.quit()
"There are $totaldocs total guest blog articles and $($totalwords.tostring('N')) words"

#clean up stuff
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($range) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($application) | Out-Null
Remove-Variable -Name application
[gc]::collect()
[gc]::WaitForPendingFinalizers()
