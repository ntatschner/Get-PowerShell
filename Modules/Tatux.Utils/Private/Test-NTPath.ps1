<#
	.SYNOPSIS
		Validate path for existances and type
	
	.DESCRIPTION
		Checks if the path is a full path or a single valid folder
	
	.PARAMETER Path
		The Path to check
	
	.EXAMPLE
				PS C:\> Test-NTPath -Path 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Test-NTPath
{
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Path
	)
	
	Begin
	{
		$Path
	}
	Process
	{
		foreach ($i in $_)
		{
			switch -regex ($i)
			{
				
				
				Default { }
			}
		}
		
	}
	End
	{
		
	}
}
