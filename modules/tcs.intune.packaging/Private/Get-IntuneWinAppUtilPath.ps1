function Get-IntuneWinAppUtilPath {
    <#
    .SYNOPSIS
        Returns where IntuneWinAppUtil.exe is kept for the current user.

    .DESCRIPTION
        IntuneWinAppUtil.exe is stored in a per-user folder (LocalApplicationData\tcs.intune.packaging)
        instead of the module folder, which is read-only for AllUsers installs. A copy left in the module
        folder by an earlier version is still used when it exists.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
    $LegacyPath = Join-Path -Path $ModuleRoot -ChildPath 'IntuneWinAppUtil.exe'
    if (Test-Path -Path $LegacyPath -PathType Leaf) {
        return $LegacyPath
    }

    $BasePath = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrEmpty($BasePath)) {
        $BasePath = [System.IO.Path]::GetTempPath()
    }
    Join-Path -Path (Join-Path -Path $BasePath -ChildPath 'tcs.intune.packaging') -ChildPath 'IntuneWinAppUtil.exe'
}
