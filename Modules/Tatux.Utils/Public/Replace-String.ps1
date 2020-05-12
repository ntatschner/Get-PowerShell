function Replace-String {
    [CmdletBinding()]
    param
    (
        [string]
        $InputString,
        [string[]]
        $Replace,
        [string]
        $With = ''
    )

    PROCESS {
        $OutputObject = $InputString
        foreach ($a in $Replace) {
            $OutputObject = $OutputObject.Replace($a, $With)        
        }
        $OutputObject
    }
}