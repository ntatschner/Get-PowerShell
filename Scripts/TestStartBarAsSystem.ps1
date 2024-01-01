# Using the Tatux.Win.Admin module and the Test-WindowsTaskbar function, we can determine if the taskbar is visible as a Scheduled task running as system
Import-Module 'D:\Nerd Stuff\Dev Stuff\Git_Repos\Get-PowerShell\Modules\Tatux.Win.Admin\Tatux.Win.Admin.psm1'

Start-Transcript -Path 'D:\Nerd Stuff\Dev Stuff\TestStartBarAsSystem.txt' -Append
$count = 0
$EndTime = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $EndTime) {
    $count++
    $taskbarStatus = Test-WindowsTaskbar
    if ($taskbarStatus) {
        Write-Host "[$($count)]Taskbar is visible."
    }
    else {
        Write-Host "[$($count)]Taskbar is not visible."
    }
    Start-Sleep -Seconds 1
    
}
Stop-Transcript