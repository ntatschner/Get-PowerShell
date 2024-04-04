function Update-NTModuleManifest {
    [CmdletBinding()]
    param(
    [ValidateScript({
        if (-Not (Test-Path -Path $_) -or $_.EndsWith(".psd1") -eq $false) {
            throw "Enter a valid manifest file."
        } else {
            $true
        }
    )]
    [string]$Path

    )
# Test if paths a valid manifest file and if so has the right field FunctionsToExport
    $ManifestFileContent = Get-Content -Path $Path -Raw

    if ($ManifestFileContent -match "FunctionsToExport =") {
        $LineToReplace = $ManifestFileContent | Select-String -Pattern "^FunctionsToExport = .*$"
    }

}