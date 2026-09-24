function New-Win32InstallExperience {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds an in-memory hashtable; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Alias('InstallTimeInMinutes')]
        [string]$maxRunTimeInMinutes,

        [ValidateSet('basedOnReturnCode', 'never', 'always', 'prompt', 'suppress')]
        [string]$restartBehavior = 'basedOnReturnCode',

        [Alias('InstallFor')]
        [ValidateSet('system', 'user')]
        [string]$runAsAccount = 'system'
    )

    $installExperienceHashTable = @{
        "maxRunTimeInMinutes" = $maxRunTimeInMinutes
        "restartBehavior"     = $restartBehavior
        "runAsAccount"        = $runAsAccount
    }
    if ([string]::IsNullOrEmpty($maxRunTimeInMinutes)) {
        $installExperienceHashTable.Remove("maxRunTimeInMinutes")
    }

    return $installExperienceHashTable
}
