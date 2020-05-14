<#
	.SYNOPSIS
		Searches a PDF document for desired test and outputs results
	
	.DESCRIPTION
		Using the find function of the .net module iTextSharpe.dll this function searches for the enter text.
	
	.PARAMETER Path
		The path of the PDF doc you would like to search, use .PDF.
	
	.PARAMETER Query
		The string to search for.
	
	.EXAMPLE
		PS C:\> Search-PDFDoc -Path $value1 -Query "data"
	
	.OUTPUTS
		Object
	
	.NOTES
		Uses the class [iTextSharpe] fir iTextSharpe.dll and thus needs the file located with the module.
#>
function Search-PDFDoc {
    [CmdletBinding(DefaultParameterSetName = 'Match')]
    [OutputType([string], ParameterSetName = 'Match')]
    param
    (
        [Parameter(ParameterSetName = 'Match',
            Mandatory = $true)]
        [ValidateScript( {
                if (-Not ($_ | Test-Path)) {
                    throw "File or folder does not exist"
                }
                if (-Not ($_ | Test-Path -PathType Leaf)) {
                    throw "The Path argument must be a file. Folder paths are not allowed."
                }
                if ($_ -notmatch "(\.pdf)") {
                    throw "The file specified in the path argument must be either of type pdf"
                }
                return $true
            })]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [string[]]$Query
    )
	
    BEGIN {
        $FunctionPath = Split-Path -Path $PSCommandPath -Parent
        try {
            Add-Type -Path "$FunctionPath\itextsharp.dll" -ErrorAction SilentlyContinue
            Write-Verbose "Class itextsharp.dll loaded."
        }
        catch {
            Write-Verbose "Class itextsharp.dll already loaded."
        }
        #Load File
        $PDFReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList $Path
    }
    PROCESS {

        for ($Page = 1 ; $Page -le $PDFReader.NumberOfPages ; $Page++) {
            # Search for queried text
            $PageText = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($PDFReader, $Page).Split([char]0x000A)
            foreach ($Q in $Query) {
                if ($PageText -match $Q) {
                    $Props = [ordered]@{
                        Name  = (Split-Path -Path $Path -Leaf)
                        Query = $Q
                        Path  = $Path
                        Match = $true -as [bool]
                    }
                    $Obj = New-Object PSObject -Property $Props
                    $Obj
                    break
                }
            }
        }
    }
    END {
		
        [gc]::collect()
		
        [gc]::WaitForPendingFinalizers()
    }
}