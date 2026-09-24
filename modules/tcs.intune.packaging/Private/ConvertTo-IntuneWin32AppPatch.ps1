function ConvertTo-IntuneWin32AppPatch {
    <#
    .SYNOPSIS
        Builds the body of a win32LobApp update (PATCH) from New-IntuneApplication settings.

    .DESCRIPTION
        Maps the ApplicationParameters of the application JSON (or a hashtable with the same names)
        to win32LobApp properties
        (https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-update):
          ApplicationName -> displayName, Description, Publisher, Developer, Owner, Notes,
          IsFeatured, InstallCommand -> installCommandLine, UninstallCommand -> uninstallCommandLine,
          InstallFor/RestartBehavior -> installExperience, LogoPath -> largeIcon, Rules -> rules.
        Graph v1.0 has no version property for Win32 apps, so Version is added to the notes as
        "Version: <version>" (as New-IntuneWin32Application does). Empty values are not sent.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory)]
        [object]$AppParameters,

        [hashtable[]]$Rules
    )

    # Reads a setting from a hashtable or an object
    function Get-Setting {
        param ([string]$Name)
        if ($AppParameters -is [System.Collections.IDictionary]) {
            $AppParameters[$Name]
        }
        else {
            $AppParameters.$Name
        }
    }

    $Body = [ordered]@{ '@odata.type' = '#microsoft.graph.win32LobApp' }
    $Map = [ordered]@{
        ApplicationName  = 'displayName'
        Description      = 'description'
        Publisher        = 'publisher'
        Developer        = 'developer'
        Owner            = 'owner'
        Notes            = 'notes'
        InstallCommand   = 'installCommandLine'
        UninstallCommand = 'uninstallCommandLine'
    }
    foreach ($Name in $Map.Keys) {
        $Value = Get-Setting -Name $Name
        if ($null -ne $Value -and "$Value" -ne '') {
            $Body[$Map[$Name]] = [string]$Value
        }
    }
    $IsFeatured = Get-Setting -Name 'IsFeatured'
    if ($null -ne $IsFeatured -and "$IsFeatured" -ne '') {
        $Body['isFeatured'] = [System.Convert]::ToBoolean($IsFeatured)
    }

    $Version = [string](Get-Setting -Name 'Version')
    if ($Version) {
        $VersionNote = "Version: $Version"
        $Existing = [string]$Body['notes']
        if (-not ($Existing -split "`r?`n" | Where-Object { $_.Trim() -eq $VersionNote })) {
            $Body['notes'] = (@($Existing, $VersionNote) | Where-Object { $_ }) -join "`n"
        }
    }

    $InstallFor = [string](Get-Setting -Name 'InstallFor')
    $RestartBehavior = [string](Get-Setting -Name 'RestartBehavior')
    if ($InstallFor -or $RestartBehavior) {
        $Body['installExperience'] = [ordered]@{
            '@odata.type'         = '#microsoft.graph.win32LobAppInstallExperience'
            runAsAccount          = $(if ($InstallFor) { $InstallFor.ToLowerInvariant() } else { 'system' })
            deviceRestartBehavior = $(if ($RestartBehavior) { $RestartBehavior } else { 'basedOnReturnCode' })
        }
    }

    $LogoPath = [string](Get-Setting -Name 'LogoPath')
    if ($LogoPath -and (Test-Path -LiteralPath $LogoPath -PathType Leaf)) {
        $Extension = [System.IO.Path]::GetExtension($LogoPath).TrimStart('.').ToLowerInvariant()
        if ($Extension -eq 'jpg') {
            $Extension = 'jpeg'
        }
        $Body['largeIcon'] = [ordered]@{
            '@odata.type' = '#microsoft.graph.mimeContent'
            type          = "image/$Extension"
            value         = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $LogoPath).ProviderPath))
        }
    }

    if ($Rules -and $Rules.Count -gt 0) {
        $Body['rules'] = @($Rules)
    }
    $Body
}
