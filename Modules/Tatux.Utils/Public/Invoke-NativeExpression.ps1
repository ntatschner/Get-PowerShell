function Invoke-NativeExpression {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Expression
    )
 
    process {
        $executable, $arguments = $expression -split ' '
        $arguments = $arguments | foreach { "'$_'" }
        $arguments = $arguments -join ' '
        $command = $executable + ' ' + $arguments
 
        if ($command) {
            Write-Verbose "Invoking '$command'"
            Invoke-Expression -command $command
        }
    }
}