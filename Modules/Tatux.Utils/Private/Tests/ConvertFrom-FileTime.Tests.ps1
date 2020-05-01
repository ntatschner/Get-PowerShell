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
	    $ScriptAnalyzerSettings = Get-Content -Path ".\PSScriptAnalyzerSettings.psd1" | Out-String | Invoke-Expression
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