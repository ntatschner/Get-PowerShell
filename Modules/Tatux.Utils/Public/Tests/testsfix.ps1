param ($Path = '.')

# version 2017-12-13

$testFiles = $(Get-ChildItem -Path $Path -Recurse *.Tests.ps1).FullName

foreach ($file in $testFiles)
{
    "Migrating '$file'"
    $content = Get-Content -Path $file -Encoding utf8
    $content = $content -replace 'Should\s+\-?Contain', 'Should -FileContentMatch'
    $content = $content -replace 'Should\s+\-?Not\s*-?Contain', 'Should -Not -FileContentMatch'
    $content = $content -replace 'Assert-VerifiableMocks', 'Assert-VerifiableMock'
    $content | Set-Content -Path $file -Encoding utf8

}
