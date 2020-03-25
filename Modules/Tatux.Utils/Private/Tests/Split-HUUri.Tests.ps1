$TestPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$FunctionFileName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$FunctionName = $FunctionFileName.Replace('.ps1', '')
. "$TestPath\$FunctionFileName"

Describe "Performing basic validation test on function $FunctionFileName" {
    Context "Function $FunctionFileName - Testing Command Output Object" {
        $global:Result = $(Invoke-Expression ($FunctionName + ' -Uri "Https://Google.com/long/path/filetodownload.exe" -Parent'))
        It "Function $FunctionFileName - Validate no exception" {
            { $Result | Should -Not -Throw }           
        }        
        It "Function $FunctionFileName - Should not be null" {
            $Result | Should -not -BeNullOrEmpty
        }
    }
}
Describe -Tags 'PSSA' -Name 'Testing against PSScriptAnalyzer rules' {
    Context 'PSSA Standard Rules' {
	    $ScriptAnalyzerSettings = Get-Content -Path "$TestPath\PSScriptAnalyzerSettings.psd1" | Out-String | Invoke-Expression
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
Describe "Split-HUUri.ps1 Custom Tests" {
    Context "Switch Output" {
        It "Parent Switch" {
            Split-HUUri -Uri "Https://Google.com/long/path/filetodownload.exe" -Parent | Should -Be "Https://google.com"
        }
        It "FullLeaf Switch" {
            Split-HUUri -Uri "Https://Google.com/long/path/filetodownload.exe" -FullLeaf | Should -Be "/long/path/filetodownload.exe"
        }
        It "Leaf Switch" {
            Split-HUUri -Uri "Https://Google.com/long/path/filetodownload.exe" -Leaf | Should -Be "filetodownload.exe"
        }
    }
}