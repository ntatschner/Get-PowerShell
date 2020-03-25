function ConvertFrom-AMTInvalidFolderCharacters
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[string]$InputString,
		[string]$ReplaceWith
	)
	
	Begin
	{
		$InvalidCharacters = '\','/',':','*','?','"','<','>','|'
	}
	Process
	{
		if ($inputString -match '[\\\/\:\*\?\"\<\>\|]') {
			foreach ($a in $InvalidCharacters) {
				$inputString = $InputString.Replace($a, $ReplaceWith)
			}
			return $InputString
		} else {
			return $InputString
		}
	}
	End
	{
		
	}
}
