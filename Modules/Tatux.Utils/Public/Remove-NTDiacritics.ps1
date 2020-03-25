function Remove-NTDiacritics
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[String]$inputString
	)
	Process
	{
		$objD = $inputString.Normalize([Text.NormalizationForm]::FormD)
		$sb = New-Object Text.StringBuilder
		
		for ($i = 0; $i -lt $objD.Length; $i++)
		{
			$c = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($objD[$i])
			if ($c -ne [Globalization.UnicodeCategory]::NonSpacingMark)
			{
				[void]$sb.Append($objD[$i])
			}
		}
		
		$sb = $sb.ToString().Normalize([Text.NormalizationForm]::FormC)
		return $sb
	}
	
}