function Get-APFCommandLine {
    <#
    .SYNOPSIS
        Returns the Intune install and uninstall command lines for an APF package.

    .DESCRIPTION
        The Intune Management Extension is a 32-bit process, so a plain powershell.exe would start
        the 32-bit Windows PowerShell on 64-bit Windows (and see the 32-bit registry view and
        Program Files). %windir%\sysnative starts the 64-bit Windows PowerShell from a 32-bit process.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    $Command = '%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File Intune-I-MainInstaller.ps1'
    [PSCustomObject]@{
        InstallCommand   = $Command
        UninstallCommand = "$Command -Uninstall"
    }
}
