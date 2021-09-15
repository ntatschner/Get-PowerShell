<#
	.SYNOPSIS
		Validate path for existances and type
	
	.DESCRIPTION
		Checks if the path is a full path or a single valid folder
	
	.PARAMETER Path
		The Path to check
	
	.EXAMPLE
				PS C:\> Test-NTValidPath -Path 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Test-NTValidPath
{
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string[]]$Path
	)
	
	Begin
	{
		if ($MyInvocation.ExpectingInput)
		{
			$Path = $_
		}
	}
	Process
	{
		foreach ($i in $Path)
		{
			$i
			switch -regex ($i)
			{
				"^(([c-z]:\\)|\/)((\\ \/)?[\w.-]*(\\|\/)?)+" {
					$true
					break
				}
				"^[a-zA-Z_\-\.]*$" {
					$false
					break
				}
				"^[a-zA-Z_\-\.\/]*$" {
					$false
					break
				}
				"^[a-zA-Z_\-\.\\]*$" {
					$false
					break
				}
				Default { Write-Error "Failed to determin path type."}
			}
		}
		
	}
	End
	{
		
	}
}
