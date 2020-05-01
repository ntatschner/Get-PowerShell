function Save-NTGitHubFile {
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
        $OutputDirectory = $PWD.Path,
        [Switch]
        $Passthru
    )
    
    begin {
        try {
            Write-Verbose "Testing if $($Uri.OriginalString) is valid and pointing to 'GitHub'"
            $NetTest = $(Test-Uri -Uri $Uri)
            If ($NetTest -eq $false -or $Uri.ToString().ToLower().Contains("github") -eq $false) {
                Write-Error "Please enter a valid URI and make sure to use a GitHub URL.."
                break
            }
        }
        catch {
            Write-Error $_
            break
        }
        # Output Obj
        $Props = @{
            [System.IO.FileInfo]'FilePath' = ''
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

                            $SecondPage = $(Invoke-WebRequest -Uri $InitialPageFullUri -Method GET -ErrorAction 'Stop').links.href | Where-Object -FilterScript { $_ -like $("*raw*" + $FileName) } | Select-Object -First 1  
                            $SecondPageFullPath = $($Uri.Scheme + "://" + $uri.Host + $SecondPage) -as [uri]
                            if ([System.String]::IsNullOrEmpty($SecondPage) -eq $false) {
                                if ((Test-Path -Path $OutputDirectory\$FileName) -eq $false) {
                                    Invoke-WebRequest -Uri $SecondPageFullPath -Method GET -OutFile $OutputFullPath -ErrorAction 'Stop'
                                    if ($Passthru) {
                                        $Obj = New-Object psobject -Property $Props
                                        $Obj.FilePath = $OutputFullPath
                                        $Obj
                                    }
                                }
                                else {
                                    if ($PSCmdlet.ShouldProcess("The file $($FileName) exists in directory $($outputDirectory), would you like to overwrite?")) {
                                        Invoke-WebRequest -Uri $SecondPageFullPath -Method GET -OutFile $OutputFullPath -ErrorAction 'Stop'
                                        if ($Passthru) {
                                            $Obj = New-Object psobject -Property $Props
                                            $Obj.FilePath = $OutputFullPath
                                            $Obj
                                        }
                                    } 
                                    else {
                                        break
                                    }
                                }
                                Write-Verbose "Successfully downloaded $($FileName) to $($OutputDirectory)"
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