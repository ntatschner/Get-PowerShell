import-module Tatux.Utils
### Search all required file type and output results
$Path = 'D:\Dropbox'
$Files = Get-ChildItem -Recurse -Path $Path -Include "*.xls", "*.xlsx", "*.doc", "*.docx", "*.pdf", "*.xlsm"

$Queries = "Nigel", "Powershell", "total","tatschner"

# Loop through files and perform searches based off the result. 
Write-Warning "Total Files: $($Files.Count)"
foreach ($File in $Files) {
    
    switch -regex ($File.Name) {
        '.*\.pdf' {
            Search-PDFDoc -Path $File.FullName -Query $Queries
         }
        '.*\.doc|.*\.docx' {
            Search-WordDoc -Path $File.FullName -Query $Queries
         }
        '.*\.xls|.*\.xlsx|.*\.xlsm' {
            Search-ExcelDoc -Path $File.FullName -Query $Queries
         }
        Default {
            Write-Warning "File match not found for $($File.FullName)"
        }
    }
}