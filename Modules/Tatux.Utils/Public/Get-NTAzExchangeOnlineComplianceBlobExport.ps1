[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ContainerURL,
    [string]
    $SRI,
    [string]
    $ExportPath,
    [string]
    [ValidateSet("PST","ZIP")]
    $FileType
)
