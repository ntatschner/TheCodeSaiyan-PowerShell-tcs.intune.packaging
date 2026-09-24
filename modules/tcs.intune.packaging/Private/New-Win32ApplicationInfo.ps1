function New-Win32ApplicationInfo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds an in-memory hashtable; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$displayName,

        [Parameter(Mandatory = $true)]
        [string]$description,

        [Parameter(Mandatory = $true)]
        [string]$publisher,

        [string]$notes,

        [string]$owner,

        [string]$developer,

        [string]$version,

        [bool]$isFeatured = $false,

        [string]$privacyInformationUrl,

        [string]$informationUrl
    )

    $CommonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
    $ApplicationInfoHashtable = @{}
    foreach ($param in $PSBoundParameters.Keys) {
        if ($param -notin $CommonParameters -and $PSBoundParameters[$param]) {
            $ApplicationInfoHashtable[$param] = $PSBoundParameters[$param]
        }
    }
    $ApplicationInfoHashtable['isFeatured'] = $isFeatured

    return $ApplicationInfoHashtable
}
