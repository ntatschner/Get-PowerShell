function Test-Uri {
    param (
        # The URI to test
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri[]]
        $Uri
    )
    Process {
        foreach ($a in $Uri) {
            $Script:Properties = @{
                [Uri]'Uri' = $a
                'Result'   = $false -as [bool]
                'Status' = ''
                'ContentType' = ''
            }
            If ($a.IsFile -eq $true) {
                Write-Error "Please enter a URI.."
                continue
            }
            if ( $a.IsAbsoluteUri -eq $false) {
                Write-Error "Please enter a valid URI, $($a) wasn't formatted correctly.."
                continue
            }
            Write-Verbose "URI $($a) Validated, moving on."
            try {
                Write-Verbose "Testing connectivity to $($a).."
                $global:NetTest = [System.Net.HttpWebRequest]::CreateDefault($a).GetResponse()
                if ($(($NetTest.ResponseUri).ToString().Split('//www.')[-1].TrimEnd('/')) -eq $($a.host)) {
                    $Obj = New-Object PSObject -Property $Properties
                    $Obj.Result = $true
                    $Obj.Status = "Success"
                    $Obj.ContentType = $NetTest.ContentType.split(';')[0]
                    $Obj
                }
                else {
                    $Obj = New-Object PSObject -Property $Properties
                    $Obj.Result = $true
                    $Obj.Status = "Connection Succeeded, but redirected to $($NetTest.ResponseUri)"
                    $Obj.ContentType = $NetTest.ContentType.split(';')[0]
                    $Obj
                }
            }
            Catch {
                Write-Error "Testing connection to URI $($a) failed..`nError:$($_.Exception.Message)"
                continue
            }
        }
    }
}