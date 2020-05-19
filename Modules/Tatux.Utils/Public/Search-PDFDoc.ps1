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
        [string[]]$Query,
        [switch]
        $OnlyMatches
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
        $Props = [ordered]@{
            Name   = (Split-Path -Path $Path -Leaf)
            Type   = (Split-Path -Path $Path -Leaf).Split('.')[-1]
            Query  = 'N/A'
            Page   = 'N/A'
            Path   = $Path
            Match  = 'N/A'
            Result = ""
        }
        try {
            $PDFReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList $Path -ErrorAction Stop
        }
        catch {
            $Obj = New-Object PSObject -Property $Props
            $Obj.Result = "Failure-Document"
        }
    }
    PROCESS {
        # Search for queried text

        foreach ($Q in $Query) {
            for ($Page = 1 ; $Page -le $PDFReader.NumberOfPages ; $Page++) {
                Try {
                    $PageText = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($PDFReader, $Page).Split([char]0x000A)
                }
                Catch {
                    $Obj = New-Object PSObject -Property $Props
                    $Obj.Result = "Failure-Search"
                    $Obj.Page = $Page
                    $Obj
                    break
                }
                $Obj = New-Object PSObject -Property $Props
                $Obj.Query = $Q
                $Obj.Page = $Page
                if ($PageText -match $Q) {
                    $Obj.Match = $true
                    $Obj.Result = "Success"
                    $Obj
                    break
                }
                else {
                    $Obj.Match = $false
                    if ($OnlyMatches -eq $false) {
                        $Obj.Result = "Success"
                        $Obj
                    }
                }
                if ($Obj.Result) {
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