function New-Win32ReturnCode {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds an in-memory hashtable; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ReturnCode,
        [Parameter(Mandatory = $true)]
        [ValidateSet('success', 'failed', 'softReboot', 'hardReboot', 'retry')]
        [string]$ReturnMessage
    )
    process {
        @{
            "returnCode" = $ReturnCode
            "type"       = $ReturnMessage
        }
    }
}
