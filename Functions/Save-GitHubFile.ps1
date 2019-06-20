function Save-GitHubFile {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'AllMatches')]
        [Parameter(ParameterSetName = 'Default')]
        [Uri]
        $Uri,
        [Parameter(ParameterSetName = 'AllMatches')]
        [Parameter(ParameterSetName = 'Default')]
        [string]
        $SearchPattern,
        [Parameter(ParameterSetName = 'AllMatches')]
        [switch]
        $AllMatches = $false,
        [Parameter(ParameterSetName = 'AllMatches')]
        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $ShowProgress,
        [Parameter(ParameterSetName = 'AllMatches')]
        [Parameter(ParameterSetName = 'Default')]
        [System.IO.DirectoryInfo]
        $OutputDirectory = $($PWD -as [System.IO.DirectoryInfo])
    )
    
    begin {
        Write-Verbose "Testing if $($Uri.OriginalString) is valid and pointing to 'GitHub'"
        If ($Uri.IsFile -eq $true -or $Uri.IsAbsoluteUri -eq $false -or $Uri.ToString().ToLower().Contains("github") -eq $false) {
            Write-Error "Please enter a valid URI and make sure to use a GitHub URL.."
            break
        }
        Write-Verbose "URI $($URI) Vailidated, moving on."
        try {
            Write-Verbose "Testing conectivity to $($Uri).."
            $global:NetTest = [System.Net.HttpWebRequest]::CreateDefault($Uri).GetResponse()
            Write-Verbose "Test Successful, moving on.."
        }
        Catch {
            Write-Error "Connection to URI $($Uri) failed, please double check the address is correct.."
            break
        }
    }
    
    process {
        switch ($PSCmdlet.ParameterSetName) { 
            'Default' {
                if ($URI.Segments.count -gt 1) {

                    Try {
                        $InitialPage = Invoke-WebRequest -Uri $Uri -Method GET -ErrorAction 'Stop'
                        $InitialPageFilter = $InitialPage.links.href | Where-Object -FilterScript { $_ -like $SearchPattern } | Select-Object -First 1
                        if ([system.string]::IsNullOrEmpty($InitialPageFilter) -eq $false) {
                        $FileName = [uri]$($URI + $InitialPageFilter).Segments[-1]
                        $OutputFullPath = $(Join-Path -Path $OutputDirectory -ChildPath $FileName)
                        Write-Verbose "Downloading requested file $($FileName) from $($Uri)"
                        if ($ShowProgress) {
                            Write-Progress -Activity "Downloadig file from $($Uri)" -Status "Starting" -Id 1 -PercentComplete 0 -CurrentOperation "Starting download of file $($FileName).."
                        }
                        if ($ShowProgress) {
                            Write-Progress -Activity "Downloadig file from $($Uri)" -Status "Downloading" -Id 1 -PercentComplete 50 -CurrentOperation "Downloading file $($FileName).."
                        }
                        $SecondPage = $(Invoke-WebRequest -Uri $InitialPageFilter -Method GET -ErrorAction 'Stop').links.href | where -FilterScript {$_ -like $("*raw." + $FileName)} | select -First 1  
                        Write-Verbose $SecondPage
                        Invoke-WebRequest -Uri $SecondPage -Method GET -ContentType $($NetTest.ContentType.split(';')[0]) -OutFile $OutputFullPath -ErrorAction 'Stop'
                        Write-Verbose "Succesfully downloaded $($FileName) to $($OutputDirectory)"
                        if ($ShowProgress) {
                            Write-Progress -Activity "Downloadig file from $($Uri)" -Status "Completed" -Id 1 -PercentComplete 100 -CurrentOperation "Finished downloading file $($FileName).." -Completed
                        }
                    } else {
                        Write-Verbose "Couldn't find the file matching patten $($SearchPattern)"
                    }
                    }
                    Catch {
                        $_
                    }

                }
                else {
                    Write-Warning "No file in path $($uri) specified"
                    break
                }
            }
            'AllMatches' {

            }
            Default { }
        }
    }
    
    end {
    }
}