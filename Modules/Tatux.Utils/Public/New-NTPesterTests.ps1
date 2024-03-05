<#
	.SYNOPSIS
		Create boilerplate pester files
	
	.DESCRIPTION
		Create boilerplate pester files for targeted function or functions in the specified output folder.
	
	.PARAMETER Source
		Source of function(s) to create the pester tests for, can be a single file or folder
	
	.PARAMETER Destination
		The path you'd like the new test file(s) to be created, this defaults to a "Test" folder in the same path as the source functions. 
	
	.EXAMPLE
		This command looks for .ps1 files in the current folder and outputs the new test files to a sub directory called 'Tests'
		PS C:\> New-NTPesterTests
	
#>
function New-NTPesterTests {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[Alias('Path')]
		[PSDefaultValue(Help = 'The current working directory')]
		[ValidateScript( {
				if ( -Not ($_ | Test-Path) ) {
					throw "File or folder does not exist"
				}
				return $true
			})]
		[System.IO.FileInfo]
		$Source = $PWD.Path,
		[ValidateNotNullOrEmpty()]
		[PSDefaultValue(Help = 'The default is Test under the source directory')]
		[string]
		$Destination
	)

	BEGIN {
		# Get source type
		$Source = $(Get-Item $Source).FullName
		if ((Get-ItemProperty -Path $Source).Attributes -eq 'Directory') {
			$SourceIsFolder = $true
			$Files = Get-ChildItem -Path $Source | Where-Object name -Like "*.ps1"
			Write-Verbose "Found $($Files.count) files"
			if ([System.String]::IsNullOrEmpty($Destination)) {
				$Destination = $(Join-Path -Path $Source -ChildPath 'Tests')
				}
		}
		else {
			if ($Source -like "*.ps1") {
				$Files = Get-item -Path $Source
				$SourceIsFile = $true
				if ([System.String]::IsNullOrEmpty($Destination)) {
				$Destination = $(Join-Path -Path $(Split-Path -Path $Source -Parent) -ChildPath 'Tests')
				}
				Write-Verbose "Targeted single file"
			}
			else {
				Write-Error "Source $($Source) is not a valid PowerShell file (.ps1)"
				break
			}
		}
		if ([system.string]::IsNullOrEmpty($Files)) {
			Write-Warning "No ps1 files found."
			break
		}
		$PesterDefaultContent = @'
BeforeAll {
	$TestPath = Split-Path -Parent -Path $PSScriptRoot

	$FunctionFileName = (Split-Path -Leaf $PSCommandPath ) -replace '\.Tests\.', '.'

	# You can use this Variable to call your function via it's name or ignore/remove as required
	$FunctionName = $FunctionFileName.Replace('.ps1', '')
	
	. $(Join-Path -Path $TestPath -ChildPath $FunctionFileName)
}
Describe -Name "Performing basic validation test on function $FunctionFileName" {
	It "Function $FunctionFileName - Testing Command Output Object" {
		# This is a template for the Pester Test, add any tests you want here
	}
}

Describe -Tags 'PSSA' -Name 'Testing against PSScriptAnalyzer rules' {
	BeforeAll {
		$ScriptAnalyzerSettings = Get-Content -Path (Join-Path -Path (Get-Location) -ChildPath 'PSScriptAnalyzerSettings.psd1') | Out-String | Invoke-Expression
		$AnalyzerIssues = Invoke-ScriptAnalyzer -Path "$TestPath\$FunctionFileName" -Settings $ScriptAnalyzerSettings
		$ScriptAnalyzerRuleNames = Get-ScriptAnalyzerRule | Select-Object -ExpandProperty RuleName
	}

	foreach ($Rule in $ScriptAnalyzerRuleNames) {
		if ($ScriptAnalyzerSettings.excluderules -notcontains $Rule) {
			It "Function $FunctionFileName should pass $Rule" {
				$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
				($Failures | Measure-Object).Count | Should -Be 0
			}
		}
		else {
			# We still want it in the tests, but since it doesn't actually get tested we will skip
			It "Function $FunctionFileName should pass $Rule" -Skip {
				$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
				($Failures | Measure-Object).Count | Should -Be 0
			}
		}
	}
}
'@	
	}
	PROCESS {
		foreach ($i in $Files) {			
			if ([System.String]::IsNullOrEmpty($Destination)) {
				# if destination path is not specified, create the files in a directory called Tests in the source function path and create the tests there.
				$Global:Destination = $(Join-Path -Path $(Split-Path -Path $($i.FullName) -Parent) -ChildPath 'Tests')
				Write-Verbose "Writing files to $Destination"
				if ($(Test-Path -Path $Destination -PathType Container) -eq $false) {
					try {
						New-Item -Path $Destination -ItemType Container -ErrorAction 'Stop'
					}
					catch {
						Write-Error "Failed to create default test folder 'Tests' in the source function directory $($i.Directory). Error: $($_.exception.message) on line $($_.Exception.Line)"
						break
					}
				}
				else {
					Write-Verbose "Destination path already exists"
				}
			}
			else {
				try {
					if ($SourceIsFolder) {
						if ($($(Test-Path -PathType Container -Path $Destination) -eq $false) -and 
						$($_ -Match "^(([c-z]:\\)|\/)((\\|\/)?[\w.-]*(\\|\/)?)+")) {
							New-Item -ItemType Container -Path $Destination -ErrorAction Stop
						}
						elseif ($(-not $($_ | Select-String -Pattern "^(([c-z]:\\)|\/)((\\|\/)?[\w.-]*(\\|\/)?)+")) -and $(Test-Path -Path $Destination -IsValid) -and
						 $($Destination -ne $(Join-Path -Path $($(Get-Item $Source).FullName) -ChildPath 'Tests'))) {
							 '2'
							New-Item -ItemType Container -Path $Destination -ErrorAction Stop
						}
						elseif ($(Test-Path -Path $Destination -IsValid) -eq $false) {
							Write-Error "Please enter a valid destination path."
							break
						}
					} elseif ($SourceIsFile) {
						if ($(Test-Path -Path $Destination) -eq $false) {
						New-Item -Path $Destination -ItemType Container -ErrorAction 'Stop'
						}
					}
					$NewFilePathandName = Join-Path -Path $Destination -ChildPath "$($i.BaseName).Tests.ps1"
					try {
						New-Item -ItemType File -Path $NewFilePathandName -Value $PesterDefaultContent -ErrorAction Stop
					}
					catch {
						Write-Error "Failed to create new test file, Error: $($_.Exception.Message) on line $($_.Exception.Line)"
						break
					}
				}
				catch {
					Write-Error "Failed to create user defined destination path, Error: $($_.Exception.Message) on line $($_.Exception.Line)"
					break
				}
			}
		}
		# Create PSScriptAnalyzerSettings.psd1 file if none exits in destination test folder
		$PSScriptAnalyzerDefault = @'
@{
# Limit tests to Warning or Error
Severity=@('Error','Warning')
# Exclude the following rule(s) ( Separated by a comma)
ExcludeRules=@('PSAvoidUsingInvokeExpression')
}
'@
		try {
			if ($(Test-Path -Path $(Join-Path -Path $Destination -ChildPath 'PSScriptAnalyzerSettings.psd1')) -eq $false) {
				New-Item -Path $(Join-Path -Path $Destination -ChildPath 'PSScriptAnalyzerSettings.psd1') -Value $PSScriptAnalyzerDefault -ItemType file -ErrorAction 'Stop'
			}
		}
		catch {
			Write-Error "Failed to create the file $(Join-Path -Path $Destination -ChildPath 'PSScriptAnalyzerSettings.psd1')"
		}
		
	}
	END {
		
	}
}
