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
		PS C:\> New-AMTPesterTests
	
#>
function New-AMTPesterTests {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[string]$Source = '.',
		[ValidateNotNullOrEmpty()]
		[string]$Destination
	)

	BEGIN {
		# Get source type
		if ((Get-ItemProperty -Path $Source).Attributes -eq 'Directory') {
			$Files = Get-ChildItem -Path $Source | Where-Object name -Like "*.ps1"
		}
		else {
			if ($Source -like "*.ps1") {
				$Files = Get-item -Path $Source
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
$TestPath = Split-Path -Parent -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
$FunctionFileName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$FunctionName = $FunctionFileName.Replace('.ps1', '')
. "$TestPath\$FunctionFileName"

Describe "Performing basic validation test on function $FunctionFileName" {
	Context "Function $FunctionFileName - Testing Command Output Object" {
		# This is a template for the Pester Test, add any tests you want here
	}
}
Describe -Tags 'PSSA' -Name 'Testing against PSScriptAnalyzer rules' {
	Context 'PSSA Standard Rules' {
		$ScriptAnalyzerSettings = Get-Content -Path $(Join-Path -Path $($PSScriptRoot) -ChildPath 'PSScriptAnalyzerSettings.psd1') | Out-String | Invoke-Expression
		$AnalyzerIssues = Invoke-ScriptAnalyzer -Path "$TestPath\$FunctionFileName"
		$ScriptAnalyzerRuleNames = Get-ScriptAnalyzerRule | Select-Object -ExpandProperty RuleName
		forEach ($Rule in $ScriptAnalyzerRuleNames)
		{
			if ($ScriptAnalyzerSettings.excluderules -notcontains $Rule)
			{
				It "Function $FunctionFileName should pass $Rule" {
					$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
					($Failures | Measure-Object).Count | Should Be 0
				}
			}
			else
			{
				# We still want it in the tests, but since it doesn't actually get tested we will skip
				It "Function $FunctionFileName should pass $Rule" -Skip {
					$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
					($Failures | Measure-Object).Count | Should Be 0
				}
			}
		
		}
	
	}
}
'@	
	}
	PROCESS {
		foreach ($i in $Files) {
			if ([system.string]::IsNullOrEmpty($Destination)) {
				# if destination path is not specified, create the files in a directory called Tests in the source function path and create the tests there.
				$DestinationPath = "$(Join-Path -Path $(Split-Path -Path $i.FullName -Parent) -ChildPath 'Tests')"
				if ((Test-Path -Path $DestinationPath) -eq $false) {
					try {
						New-Item -Path $DestinationPath -ItemType Container
					} catch {
						Write-Error "Failed to create default test folder 'Tests' in the source function directory $($i.Directory)."
						break
					}
				}
			}
			else {
				try {
					if (Test-Path -Path $Destination) {
						$DestinationPath = $Destination
					}
					elseif (Test-Path -Path $Destination -IsValid) {
						New-Item -ItemType Container -Path $Destination -ErrorAction Stop
					}
					else {
						Write-Error "Please enter a valid destination path."
						break
					}
				}
				catch {
					Write-Error "Failed to create destination path, Error: $($_.Exception.Message)"
					break
				}
			}
			$NewFilePathandName = Join-Path -Path $DestinationPath -ChildPath "$($i.BaseName).Tests.ps1"
			try {
				New-Item -ItemType File -Path $NewFilePathandName -Value $PesterDefaultContent -ErrorAction Stop
			}
			catch {
				Write-Error "Failed to create new test file, Error: $($_.Exception.Message)"
			}
		}
		
	}
	END {
		
	}
}
