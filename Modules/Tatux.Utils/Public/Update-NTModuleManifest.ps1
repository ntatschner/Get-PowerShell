function Update-NTModuleManifest {
    [CmdletBinding()]
    param(
    [ValidateScript({
        if (-Not (Test-Path -Path $_)) {
            throw "Enter a valid path."
        } else {
            $true
        }
    )]
    [string]$Path

    )
# Test if paths a valid manifest file and if so has the right field FunctionsToExport


}