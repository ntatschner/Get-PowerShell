function Test-Uri {
    param (
        # The URI to test
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Uri[]]
        $Uri
    )
    Process {
        foreach ($a in $Uri) {
            $Script:Properties = @{
                [Uri]'Uri' = $a
                'Result'   = $false -as [bool]
                'Status' = ''
            }
            If ($a.IsFile -eq $true) {
                Write-Error "Please enter a URI.."
                continue
            }
            if ( $a.IsAbsoluteUri -eq $false) {
                Write-Error "Please enter a valid URI, $($a) wasn't formatted correctly.."
                continue
            }
            Write-Verbose "URI $($a) Vailidated, moving on."
            try {
                Write-Verbose "Testing conectivity to $($a).."
                $global:NetTest = [System.Net.HttpWebRequest]::CreateDefault($a).GetResponse()
                if ($(($NetTest.ResponseUri).ToString().Split('//www.')[-1].TrimEnd('/')) -eq $($a.host)) {
                    $Obj = New-Object PSObject -Property $Properties
                    $Obj.Result = $true
                    $Obj.Status = "Success"
                    $Obj
                }
                else {
                    $Obj = New-Object PSObject -Property $Properties
                    $Obj.Result = $false
                    $Obj.Status = "Connection Succeeded, but redirected to $($NetTest.ResponseUri)"
                    $Obj
                }
            }
            Catch {
                $_
                Write-Error "Testing connection to URI $($a) failed.."
                continue
            }
        }
    }
}