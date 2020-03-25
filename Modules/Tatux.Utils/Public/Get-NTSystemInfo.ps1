<#
	.SYNOPSIS
		To gather and instantiate the servers details
	
	.DESCRIPTION
		Capsulizing WMI queries to gather and propagate new objects for output for queried servers
	
	.PARAMETER ComputerName
		Computer Name of the Server you would like to connect to.
	
	.EXAMPLE
		PS C:\> Get-NTServerDetails -ComputerName 'Value1'
	
	.NOTES
		Created by Nigel Tatschner 2015.
#>
function Get-NTSystemInfo
{
	[CmdletBinding()]
	[OutputType([Object])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   HelpMessage = 'Enter the Name of the Server you would like to connect to.')]
		[Alias('ServerName')]
		[string]$ComputerName
	)
	
	Begin
	{
		try
		{
			Write-Verbose "Testing Connection to Server $ComputerName"
			Test-Connection -ComputerName $ComputerName -ErrorAction Stop | Out-Null
			Write-Verbose "Connection to $($ComputerName) was successfully, moving on to wmi queries"
		}
		Catch
		{
			Write-Verbose "Could not connect to $ComputerName"
			Write-Error -Message "Could not connect to $($ComputerName)" -Category ConnectionError -RecommendedAction 'Check if the computer name is correct and it is on.'
			Continue
		}

	}
	Process
	{
		try
		{
			Write-Verbose 'Getting Computer System details'
			$ComputerSystemDetails = Get-WmiObject -ComputerName $ComputerName -Class Win32_ComputerSystem -ErrorAction Stop
			Write-Verbose 'Computer System Details Gathered.'
		}
		catch [System.UnauthorizedAccessException]
		{
			Write-Verbose "Could not connect to $($ComputerName) via WMI - Access Denied"
			Write-Error -Message "Access Denied - Could not access computer system details from $ComputerName via WMI" -Category AuthenticationError -RecommendedAction 'Check if the user has access.'
			return
		}
		catch [Exception]
		{
			if ($_.Exception.GetType().Name -eq "COMException")
			{
				Write-Verbose "Could not connect to $($ComputerName) via WMI - Connectivity Issues"
				Write-Error -Message "Connectivity Issues - Could not access computer system details from $($ComputerName) via WMI" -Category ConnectionError -RecommendedAction 'Check if the computer name is correct and the firewall is off.'
				return
			}
			else
			{
				Write-Verbose "Could not connect to $($ComputerName) via WMI - Unknown Error"
				Write-Error -Message "Unknown Error - Could not access computer system details from $($ComputerName) via WMI" -Category NotSpecified
				return
			}
		}
		Try
		{
			Write-Verbose "Getting Operating System details"
			$OperatingSystemDetails = Get-WmiObject -ComputerName $ComputerName -Class Win32_OperatingSystem -ErrorAction Stop
			Write-Verbose "Operating System Details Gathered."
		}
		catch
		{
			Write-Verbose "Could not get operating system details from $ComputerName via WMI"
			Write-Error -Message "Could not get operating system details from $($ComputerName) via WMI" -Category ConnectionError -RecommendedAction 'Check if the user has access and the firewall is off.'
		}
		Try
		{
			Write-Verbose "Getting Network Details"
			$NetworkConfigurationDetails = Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -ErrorAction Stop
			Write-Verbose "Network Details Gathered"
		}
		Catch
		{
			Write-Verbose "Could not get network details from $ComputerName via WMI"
			Write-Error -Message "Could not get network details from $($ComputerName) via WMI" -Category ConnectionError -RecommendedAction 'Check if the user has access and the firewall is off.'
		}
		
		switch ($OperatingSystemDetails.OSLanguage) {
			1 { $OSLanguage = 'Arabic' }
			4 { $OSLanguage = 'Chinese - China' }
			9 { $OSLanguage = 'English' }
			1025 { $OSLanguage = 'Arabic - Saudi Arabia' }
			1026 { $OSLanguage = 'Bulgarian' }
			1027 { $OSLanguage = 'Catalan' }
			1028 { $OSLanguage = 'Chinese  - Taiwan' }
			1029 { $OSLanguage = 'Czech' }
			1030 { $OSLanguage = 'Danish' }
			1031 { $OSLanguage = 'German - Germany' }
			1032 { $OSLanguage = 'Greek' }
			1033 { $OSLanguage = 'English - United States' }
			1034 { $OSLanguage = 'Spanish - Traditional Sort' }
			1035 { $OSLanguage = 'Finnish' }
			1036 { $OSLanguage = 'French - France' }
			1037 { $OSLanguage = 'Hebrew' }
			1038 { $OSLanguage = 'Hungarian' }
			1039 { $OSLanguage = 'Icelandic' }
			1040 { $OSLanguage = 'Italian - Italy' }
			1041 { $OSLanguage = 'Japanese' }
			1042 { $OSLanguage = 'Korean' }
			1043 { $OSLanguage = 'Dutch - Netherlands' }
			1044 { $OSLanguage = 'Norwegian - Bokmal' }
			1045 { $OSLanguage = 'Polish' }
			1046 { $OSLanguage = 'Portuguese - Brazil' }
			1047 { $OSLanguage = 'Rhaeto-Romanic' }
			1048 { $OSLanguage = 'Romanian' }
			1049 { $OSLanguage = 'Russian' }
			1050 { $OSLanguage = 'Croatian' }
			1051 { $OSLanguage = 'Slovak' }
			1052 { $OSLanguage = 'Albanian' }
			1053 { $OSLanguage = 'Swedish' }
			1054 { $OSLanguage = 'Thai' }
			1055 { $OSLanguage = 'Turkish' }
			1056 { $OSLanguage = 'Urdu' }
			1057 { $OSLanguage = 'Indonesian' }
			1058 { $OSLanguage = 'Ukrainian' }
			1059 { $OSLanguage = 'Belarusian' }
			1060 { $OSLanguage = 'Slovenian' }
			1061 { $OSLanguage = 'Estonian' }
			1062 { $OSLanguage = 'Latvian' }
			1063 { $OSLanguage = 'Lithuanian' }
			1065 { $OSLanguage = 'Persian' }
			1066 { $OSLanguage = 'Vietnamese' }
			1069 { $OSLanguage = 'Basque ' }
			1070 { $OSLanguage = 'Serbian' }
			1071 { $OSLanguage = 'Macedonian ' }
			1072 { $OSLanguage = 'Sutu' }
			1073 { $OSLanguage = 'Tsonga' }
			1074 { $OSLanguage = 'Tswana' }
			1076 { $OSLanguage = 'Xhosa' }
			1077 { $OSLanguage = 'Zulu' }
			1078 { $OSLanguage = 'Afrikaans' }
			1080 { $OSLanguage = 'Faeroese' }
			1081 { $OSLanguage = 'Hindi' }
			1082 { $OSLanguage = 'Maltese' }
			1084 { $OSLanguage = 'Scottish Gaelic ' }
			1085 { $OSLanguage = 'Yiddish' }
			1086 { $OSLanguage = 'Malay - Malaysia' }
			2049 { $OSLanguage = 'Arabic - Iraq' }
			2052 { $OSLanguage = 'Chinese  - PRC' }
			2055 { $OSLanguage = 'German - Switzerland' }
			2057 { $OSLanguage = 'English - United Kingdom' }
			2058 { $OSLanguage = 'Spanish - Mexico' }
			2060 { $OSLanguage = 'French - Belgium' }
			2064 { $OSLanguage = 'Italian - Switzerland' }
			2067 { $OSLanguage = 'Dutch - Belgium' }
			2068 { $OSLanguage = 'Norwegian - Nynorsk' }
			2070 { $OSLanguage = 'Portuguese - Portugal' }
			2072 { $OSLanguage = 'Romanian - Moldova' }
			2073 { $OSLanguage = 'Russian - Moldova' }
			2074 { $OSLanguage = 'Serbian - Latin' }
			2077 { $OSLanguage = 'Swedish - Finland' }
			3073 { $OSLanguage = 'Arabic - Egypt' }
			3076 { $OSLanguage = 'Chinese  - Hong Kong SAR' }
			3079 { $OSLanguage = 'German - Austria' }
			3081 { $OSLanguage = 'English - Australia' }
			3082 { $OSLanguage = 'Spanish - International Sort' }
			3084 { $OSLanguage = 'French - Canada' }
			3098 { $OSLanguage = 'Serbian - Cyrillic' }
			4097 { $OSLanguage = 'Arabic - Libya' }
			4100 { $OSLanguage = 'Chinese  - Singapore' }
			4103 { $OSLanguage = 'German - Luxembourg' }
			4105 { $OSLanguage = 'English - Canada' }
			4106 { $OSLanguage = 'Spanish - Guatemala' }
			4108 { $OSLanguage = 'French - Switzerland' }
			5121 { $OSLanguage = 'Arabic - Algeria' }
			5127 { $OSLanguage = 'German - Liechtenstein' }
			5129 { $OSLanguage = 'English - New Zealand' }
			5130 { $OSLanguage = 'Spanish - Costa Rica' }
			5132 { $OSLanguage = 'French - Luxembourg' }
			6145 { $OSLanguage = 'Arabic - Morocco' }
			6153 { $OSLanguage = 'English - Ireland' }
			6154 { $OSLanguage = 'Spanish - Panama' }
			7169 { $OSLanguage = 'Arabic - Tunisia' }
			7177 { $OSLanguage = 'English - South Africa' }
			7178 { $OSLanguage = 'Spanish - Dominican Republic' }
			8193 { $OSLanguage = 'Arabic - Oman' }
			8201 { $OSLanguage = 'English - Jamaica' }
			8202 { $OSLanguage = 'Spanish - Venezuela' }
			9217 { $OSLanguage = 'Arabic - Yemen' }
			9226 { $OSLanguage = 'Spanish - Colombia' }
			10241 { $OSLanguage = 'Arabic - Syria' }
			10249 { $OSLanguage = 'English - Belize' }
			10250 { $OSLanguage = 'Spanish - Peru' }
			11265 { $OSLanguage = 'Arabic - Jordan' }
			11273 { $OSLanguage = 'English - Trinidad' }
			11274 { $OSLanguage = 'Spanish - Argentina' }
			12289 { $OSLanguage = 'Arabic - Lebanon' }
			12298 { $OSLanguage = 'Spanish - Ecuador' }
			13313 { $OSLanguage = 'Arabic - Kuwait' }
			13322 { $OSLanguage = 'Spanish - Chile' }
			14337 { $OSLanguage = 'Arabic - U.A.E.' }
			14346 { $OSLanguage = 'Spanish - Uruguay' }
			15361 { $OSLanguage = 'Arabic - Bahrain' }
			15370 { $OSLanguage = 'Spanish - Paraguay' }
			16385 { $OSLanguage = 'Arabic - Qatar' }
			16394 { $OSLanguage = 'Spanish - Bolivia' }
			17418 { $OSLanguage = 'Spanish - El Salvador' }
			18442 { $OSLanguage = 'Spanish - Honduras' }
			19466 { $OSLanguage = 'Spanish - Nicaragua' }
			20490 { $OSLanguage = 'Spanish - Puerto Rico' }
			
			default { $OSLanguage = 'Unknown'}
		}
		$BootTime = $([Management.ManagementDateTimeConverter]::ToDateTime($OperatingSystemDetails.LastBootUpTime))
		$CurrentTime = $([Management.ManagementDateTimeConverter]::ToDateTime($OperatingSystemDetails.LocalDateTime))
		$Uptime = New-TimeSpan -Start $BootTime -End $CurrentTime
		
		Clear-Variable -Name AdaptersWithIPs -ErrorAction SilentlyContinue | Out-Null
		Clear-Variable -Name AdaptersSpeed -ErrorAction SilentlyContinue | Out-Null
		$AdaptersWithIPs = @()
		foreach ($a in $NetworkConfigurationDetails)
		{
			if (
			$a.IPAddress -gt "" -or $a.IPAddress.count -gt 1)
			{
				$AdaptersWithIPs += $a
			}
		}
		$AdapterDescription = [string]::join(" ; ", ($AdaptersWithIPs.Description))
		$IPAddresses = [string]::join(" ; ", ($AdaptersWithIPs.IPAddress))
		$DefaultGateway = [string]::join(" ; ", ($AdaptersWithIPs.DefaultIPGateway))
		$DNSSearchOrder = [string]::join(" ; ", ($AdaptersWithIPs.DNSServerSearchOrder))
		$MACAddresses = [string]::join(" ; ", ($AdaptersWithIPs.MACAddress))
		$DHCPEnabled = [string]::join(" ; ", ($AdaptersWithIPs.DHCPEnabled))
		
		$Obj = New-Object -TypeName System.Management.Automation.PSObject
		$Obj | Add-Member -Type NoteProperty -Name 'InputHostName' -Value $ComputerName
		$Obj | Add-Member -Type NoteProperty -Name 'Hostname' -Value $($ComputerSystemDetails.DNSHostName)
		$Obj | Add-Member -Type NoteProperty -Name 'OSName' -Value $($OperatingSystemDetails.Name -split '\|')[0]
		$Obj | Add-Member -Type NoteProperty -Name 'OSBuildNumber' -Value $($OperatingSystemDetails.BuildNumber)
		$Obj | Add-Member -Type NoteProperty -Name 'OSLanguage' -Value $OSLanguage
		$Obj | Add-Member -Type NoteProperty -Name 'LastBootTime' -Value $BootTime
		$Obj | Add-Member -Type NoteProperty -Name 'TotalUptime' -Value $("{0} D {1} H {2} M {3} S" -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes, $Uptime.Seconds)
		$Obj | Add-Member -Type NoteProperty -Name 'LoggedOnUser' -Value $($ComputerSystemDetails.Username)
		$Obj | Add-Member -Type NoteProperty -Name 'NetworkAdapter' -Value $AdapterDescription
		$Obj | Add-Member -Type NoteProperty -Name 'IPAddresses' -Value $IPAddresses
		$Obj | Add-Member -Type NoteProperty -Name 'DefaultGateways' -Value $DefaultGateway
		$Obj | Add-Member -Type NoteProperty -Name 'DNSSearchOrder' -Value $DNSSearchOrder
		$Obj | Add-Member -Type NoteProperty -Name 'MACAddresses' -Value $MACAddresses
		$Obj | Add-Member -Type NoteProperty -Name 'DHCPEnabled' -Value $DHCPEnabled

		Write-Output $Obj
	}
	End
	{
		
	}
}