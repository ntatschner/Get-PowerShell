<#
	.SYNOPSIS
		Using the legacy 'netstat' to parse information about TCP connections on a host
	
	.DESCRIPTION
		Gather details from netstat about TCP connection an a Windows host, this should be as backward compatible as possible to allow the widest application.
	
	.PARAMETER DisplayExecutable
		Displays the executable involved in creating each connection or listening port. In some cases well-known executables host multiple independent components, and in these cases the sequence of components involved in creating the connection or listening port is displayed. In this case the executable name is in [] at the bottom, on top is the component it called, and so forth until TCP/IP was reached. Note that this option can be time-consuming and will fail unless you have sufficient permissions.
	
	.PARAMETER ResolveAddress
		Resolves the remote hosts DNS name if possible
	
	.PARAMETER IgnoreLoopback
		Displays only locally assigned address connection info
	
	.PARAMETER ComputerName
		A remote host to run the command on
	
	.EXAMPLE
		PS C:\> Get-NTTCPConnectionInfo
	
	.OUTPUTS
		object, object
#>
function Get-NTTCPConnectionInfo {
	[CmdletBinding(DefaultParameterSetName = 'Default',
		ConfirmImpact = 'None')]
	[OutputType([object], ParameterSetName = 'Default')]
	[OutputType([object], ParameterSetName = 'Executable')]
	[OutputType([object])]
	param
	(
		[Parameter(ParameterSetName = 'Executable')]
		[Alias('b')]
		[switch]$DisplayExecutable,
		[Parameter(ParameterSetName = 'Default')]
		[Parameter(ParameterSetName = 'Executable')]
		[Alias('f')]
		[switch]$ResolveAddress,
		[Parameter(ParameterSetName = 'Default')]
		[Parameter(ParameterSetName = 'Executable')]
		[switch]$IgnoreLoopback,
		[Parameter(ParameterSetName = 'Default')]
		[Parameter(ParameterSetName = 'Executable')]
		[Alias('cn')]
		[string]$ComputerName = 'localhost'
	)
	
	BEGIN {
		# Creating the properties for the switches.
		# Main Properties
		$MainProps = [ordered]@{
			protocol      = ""
			localaddress  = ""
			remoteaddress = ""
			state         = ""
		}
		
		# Executable properties
		$ExecutableProps = [ordered]@{
			process = "" -as [System.Diagnostics.Process]
		}
		# Limit default properties to display on the process output
		# so we can maintain the object integrity whiles being selective about default values
		$defaultDisplaySet = "ProcessName", "ID"
		$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultDisplaySet)
		# We add this to the process object to apply our limiting 
		$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
	}
	PROCESS {
		switch ($PSCmdlet.ParameterSetName) {
			"Executable" {
				if ($ResolveAddress) { 
					$MainProps = $MainProps + $ExecutableProps
					try {
						netstat -p tcp -o -f | ForEach-Object -Process {
							if ([string]::IsNullOrEmpty($_)) { continue }
							$NTTCPObj = New-Object system.collections.arraylist
							$_.split('') | Foreach-Object -Process {
								if ([string]::IsNullOrEmpty($_) -eq $false) {
									$NTTCPObj.Add($_) | Out-Null
								}
							}
							$obj = New-Object System.Management.Automation.PSObject -Property $MainProps
						
							# Getting Process info
							$Process = Get-Process -Id $NTTCPObj[5] | Select-Object -Property *
						
							$Process | Add-Member MemberSet PSStandardMembers $PSStandardMembers
							$obj.protocol = $NTTCPObj[0]
							$obj.localaddress = $NTTCPObj[1]
							$obj.remoteaddress = $NTTCPObj[2]
							$obj.state = $NTTCPObj[3]
							$Obj.process = $Process
							$obj
						}
					}
					catch {
						$_
					}
				}
				else {
					$MainProps = $MainProps + $ExecutableProps
					try {
						netstat -p tcp -o | ForEach-Object -Process {
							if ([string]::IsNullOrEmpty($_)) { continue }
							$NTTCPObj = New-Object system.collections.arraylist
							$_.split('') | Foreach-Object -Process {
								if ([string]::IsNullOrEmpty($_) -eq $false) {
									$NTTCPObj.Add($_) | Out-Null
								}
							}
							$obj = New-Object System.Management.Automation.PSObject -Property $MainProps
						
							# Getting Process info
							$Process = Get-Process -Id $NTTCPObj[5] | Select-Object -Property *
						
							$Process | Add-Member MemberSet PSStandardMembers $PSStandardMembers
							$obj.protocol = $NTTCPObj[0]
							$obj.localaddress = $NTTCPObj[1]
							$obj.remoteaddress = $NTTCPObj[2]
							$obj.state = $NTTCPObj[3]
							$Obj.process = $Process
							$obj
						}
					}
					catch {
						$_
					}
				}
			}
			"Default" {
				if ($ResolveAddress) {
					try {
						netstat -p tcp -f | ForEach-Object -Process {
							if ([string]::IsNullOrEmpty($_)) { continue }
							$NTTCPObj = New-Object system.collections.arraylist
							$_.split('') | Foreach-Object -Process {
								if ([string]::IsNullOrEmpty($_) -eq $false) {
									$NTTCPObj.Add($_) | Out-Null
								}
							}
							$obj = New-Object System.Management.Automation.PSObject -Property $MainProps
							$obj.protocol = $NTTCPObj[0]
							$obj.localaddress = $NTTCPObj[1]
							$obj.remoteaddress = $NTTCPObj[2]
							$obj.state = $NTTCPObj[3]
							$obj
						}
					}
					catch {
						$_
					}
				}
				else {
					try {
						netstat -p tcp | ForEach-Object -Process {
							if ([string]::IsNullOrEmpty($_)) { continue }
							$NTTCPObj = New-Object system.collections.arraylist
							$_.split('') | Foreach-Object -Process {
								if ([string]::IsNullOrEmpty($_) -eq $false) {
									$NTTCPObj.Add($_) | Out-Null
								}
							}
							$obj = New-Object System.Management.Automation.PSObject -Property $MainProps
							$obj.protocol = $NTTCPObj[0]
							$obj.localaddress = $NTTCPObj[1]
							$obj.remoteaddress = $NTTCPObj[2]
							$obj.state = $NTTCPObj[3]
							$obj
						}
					}
					catch {
						$_
					}
				}
			}
			Default { }
		}
	}
	END {
		
	}
}
