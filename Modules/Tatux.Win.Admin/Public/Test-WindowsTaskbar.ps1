# This function determines if the Windows Taskbar is loaded using a c# class.
function Test-WindowsTaskbar {
    begin {
        try {
            if (-not ([System.Management.Automation.PSTypeName]'Taskbar').Type) {
                Add-Type -Path "$PSScriptRoot\..\Classes\Taskbar.cs" -ErrorAction Stop
            }
            
        }
        catch {
            Write-Error "Failed to load Taskbar class."
            $_
            break
        }
    }
    process {
        $taskbarStatus = [Taskbar]::IsTaskbarLoaded()
        if ($taskbarStatus) {
            Write-Verbose "Taskbar is visible."
            $true
        }
        else {
            Write-Verbose "Taskbar is not visible."
            $false
        }
    }
}