function New-Win32Installation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds an in-memory hashtable; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$installCommandLine,

        [Parameter(Mandatory = $true)]
        [string]$uninstallCommandLine,

        [bool]$allowAvailableUninstall = $false
    )

    $InstallationHashTable = @{
        installCommandLine      = $installCommandLine
        uninstallCommandLine    = $uninstallCommandLine
        allowAvailableUninstall = $allowAvailableUninstall
    }

    return $InstallationHashTable
}
