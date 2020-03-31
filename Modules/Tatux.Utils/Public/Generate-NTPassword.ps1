<#
	.SYNOPSIS
		Generates a password based on a series of characters in a random order
	
	.DESCRIPTION
		Generates a password based on a series of characters in a random order
	
	.PARAMETER length
		Length of the password to generate
	
	.NOTES
		Additional information about the function.
#>
function Generate-NTPassword {
	[CmdletBinding()]
	param
	(
		[Parameter(HelpMessage = 'Enter length of the password you would like to generate in numbers')]
		[int]$length = 10
	)
	PROCESS {	
		$SourceData = $NULL; For ($a = 33; $a –le 126; $a++) { $SourceData += , [char][byte]$a } # Converts numbers to legal character bytes for output
	
		For ($loop = 1; $loop –le $length; $loop++) {
			# Loops for the ammount of length specified
		
			$Password += ($SourceData | Get-Random) # Gets a randon character from list and stores it for output
		
		}
	
		$Props = @{ 'Password' = $Password } # Creates the property for the output object
	
		$Password = New-Object -TypeName PSObject -Property $Props # creates the output object
	
		Write-Output $Password
	}
} # End of the function