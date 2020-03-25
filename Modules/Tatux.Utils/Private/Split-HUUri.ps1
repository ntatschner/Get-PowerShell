<#
.SYNOPSIS
    Splits a URI
.DESCRIPTION
    Splits a URI from its host to the local path
.EXAMPLE
    PS C:\> Split-HUUri -URI "https://google.com/Search=test/" -Parent
    https://google.com
.INPUTS
    [string]
.OUTPUTS
    [string]
#>
function Split-HUUri {
    [CmdletBinding(DefaultParameterSetName = 'Parent')]
    param (
        [uri]
        $Uri,
        [Parameter(ParameterSetName = 'Parent')]
        [switch]
        $Parent,
        [Parameter(ParameterSetName = 'Leaf')]
        [switch]
        $Leaf,
        [Parameter(ParameterSetName = 'FullLeaf')]
        [switch]
        $FullLeaf
    )
    process {
        switch ($PsCmdlet.ParameterSetName) {
            'Parent' {
                $outputURL = $Uri.Scheme + "://" + $Uri.Authority
                $outputURL
                break
            }
            'FullLeaf' {
                $outputURL = ($Uri -as [uri]).PathandQuery
                $outputURL
                break
            }
            'Leaf' {
                $outputURL = ($Uri -as [uri]).Segments[-1]
                $outputURL
                break
            }
        }
    }
}