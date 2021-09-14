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
<<<<<<< HEAD
		[string[]]$Path
=======
		[string]$Path
>>>>>>> 858f1bbdfc54a6780a3780dc594324d73a01beab
	)
	
	Begin
	{
<<<<<<< HEAD
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
=======
		$Path
	}
	Process
	{
		foreach ($i in $_)
		{
			switch -regex ($i)
			{
				
				
				Default { }
>>>>>>> 858f1bbdfc54a6780a3780dc594324d73a01beab
			}
		}
		
	}
	End
	{
		
	}
}
