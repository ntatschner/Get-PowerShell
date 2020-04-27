<#
.SYNOPSIS
    Proxied Invoke-WebRequest with TLS selection
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
[CmdletBinding()]
param(
    #[Microsoft.PowerShell.Commands.WebRequestMethod]
    ${Method},

    [switch]
    ${UseBasicParsing},

    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Uri},

    [Microsoft.PowerShell.Commands.WebRequestSession]
    ${WebSession},

    [Alias('SV')]
    [string]
    ${SessionVariable},

    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${UseDefaultCredentials},

    [ValidateNotNullOrEmpty()]
    [string]
    ${CertificateThumbprint},

    [ValidateNotNull()]
    [X509Certificate]
    ${Certificate},

    [string]
    ${UserAgent},

    [switch]
    ${DisableKeepAlive},

    [ValidateRange(0, 2147483647)]
    [int]
    ${TimeoutSec},

    [System.Collections.IDictionary]
    ${Headers},

    [ValidateRange(0, 2147483647)]
    [int]
    ${MaximumRedirection},

    [uri]
    ${Proxy},

    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [switch]
    ${ProxyUseDefaultCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [System.Object]
    ${Body},

    [string]
    ${ContentType},

    [ValidateSet('chunked','compress','deflate','gzip','identity')]
    [string]
    ${TransferEncoding},

    [string]
    ${InFile},

    [string]
    ${OutFile},

    [switch]${PassThru}),

	[ValidateSet('TLS', 'TLS1.1', 'TLS1.2', 'TLS1.3')]
	[string]$TlsVersion

begin
{

	try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Invoke-RestMethod', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

Process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}