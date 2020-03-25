Function ConvertFrom-FileTime {
    Param (
        [Parameter(ValueFromPipeline = $true, mandatory = $true)]
        $FileTime
    )
    
    process {
        if ($FileTime -ne '9223372036854775807') {
        [datetime]::FromFileTime($FileTime)
        } else {
            Return "<Never>"
        }
    }
}