function Save-GitHubFile {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Default')]
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
        $OutputDirectory = $PWD.Path
    )
    
    begin {
        try {
            Write-Verbose "Testing if $($Uri.OriginalString) is valid and pointing to 'GitHub'"
            If ($(Test-Uri -Uri $Uri) -eq $false -or $Uri.ToString().ToLower().Contains("github") -eq $false) {
                Write-Error "Please enter a valid URI and make sure to use a GitHub URL.."
                break
            }
        }
        catch {
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
                        $InitialPageFullUri = $($URI.Host + $InitialPageFilter)
                        if ([system.string]::IsNullOrEmpty($InitialPageFilter) -eq $false) {
                            $FileName = $($URI.Host + $InitialPageFilter).split('/')[-1]
                            $OutputFullPath = $(Join-Path -Path $OutputDirectory -ChildPath $FileName)
                            Write-Verbose "Downloading requested file $($FileName) from $($Uri)"
                            if ($ShowProgress) {
                                Write-Progress -Activity "Downloadig file from $($Uri)" -Status "Starting" -Id 1 -PercentComplete 0 -CurrentOperation "Starting download of file $($FileName).."
                            }
                            if ($ShowProgress) {
                                Write-Progress -Activity "Downloadig file from $($Uri)" -Status "Downloading" -Id 1 -PercentComplete 50 -CurrentOperation "Downloading file $($FileName).."
                            }
                            $SecondPage = $(Invoke-WebRequest -Uri $InitialPageFullUri -Method GET -ErrorAction 'Stop').links.href | where -FilterScript { $_ -like $("*raw*" + $FileName) } | select -First 1  
                            $SecondPaageFullPath = $($uri.Host + $SecondPage)
                            if ([System.String]::IsNullOrEmpty($SecondPage) -eq $false) {
                                if ($PSCmdlet.ShouldProcess("Should Process?")) {
                                        Invoke-WebRequest -Uri $SecondPaageFullPath -Method GET -ContentType $($NetTest.ContentType.split(';')[0]) -OutFile $OutputFullPath -ErrorAction 'Stop'
                                    } 
                                    else 
                                    {
                                        break
                                    }
                                    Write-Verbose "Succesfully downloaded $($FileName) to $($OutputDirectory)"
                                    if ($ShowProgress) {
                                        Write-Progress -Activity "Downloadig file from $($Uri)" -Status "Completed" -Id 1 -PercentComplete 100 -CurrentOperation "Finished downloading file $($FileName).." -Completed
                                    }
                                }
                                else {
                                    Write-Error "Second link empty"
                                    break
                                }
                            }
                            else {
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