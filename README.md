# tcs.intune.packaging

PowerShell functions to build, package and deploy applications and configuration packages for
Microsoft Intune: Win32 `.intunewin` packages, Application Packaging Framework (APF) installer
packages, detection/requirement rules and deployment groups.

Part of the tcs module suite; built on [tcs.core](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core).

## Requirements

- **Windows.** The module uses the Windows Installer COM object, Authenticode signing and
  Microsoft's `IntuneWinAppUtil.exe`. It runs on Windows PowerShell 5.1 and PowerShell 7 on Windows.
- **tcs.core 0.3.0 or later** (installed automatically as a required module).
- Optional, only for the commands that talk to Microsoft Entra ID / Intune:
  - `Microsoft.Entra` (`New-ApplicationDeploymentGroup -CreateGroups`)
  - `Microsoft.Graph.Identity.DirectoryManagement` (`-AdminUnitId`)
  - `Microsoft.Graph.Authentication` (`Publish-IntuneAppPackage`, `New-IntuneWin32Application`,
    `New-IntuneApplication -Publish` and the `*-IntuneWin32App*` commands), connected with
    `Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All` (add `Group.Read.All` to assign to a
    group by display name)

## Installation

```powershell
Install-Module -Name tcs.intune.packaging -Scope CurrentUser
```

From source:

```powershell
git clone https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.intune.packaging.git
Import-Module ./TheCodeSaiyan-PowerShell-tcs.intune.packaging/modules/tcs.intune.packaging/tcs.intune.packaging.psd1
```

## Functions

| Function | Purpose |
| --- | --- |
| `New-APFDeployment` | Creates an APF package folder for an MSI/EXE installer (installer scripts, config, detection script) and optionally a `.intunewin` |
| `New-APFConfigDeployment` | Creates APF configuration packages: Registry, Files, PowerShellProfiles, Script-OS, Script-App, Script-User, Custom, WindowsFeature, StandAlone-Exe, Standalone-Application |
| `New-IntuneWin32AppPackage` | Wraps a source folder into a `.intunewin` package with `IntuneWinAppUtil.exe` |
| `Get-IntuneWinPackageInfo` | Reads the metadata (setup file, sizes, MSI details) of a `.intunewin` package |
| `New-IntuneApplication` | Writes the application JSON configuration and the `.intunewin` package, and optionally publishes and assigns them |
| `New-IntuneWin32Rule` | Builds a Win32 app detection or requirement rule (file, registry, script, MSI) |
| `Publish-IntuneAppPackage` | Publishes a package created by `New-IntuneApplication`: creates the Win32 app, or with `-Force` uploads a new content version and updates the app; then assigns it |
| `New-IntuneWin32Application` | Creates (or clones) a Win32 app in Intune and uploads its `.intunewin` content through Microsoft Graph |
| `Get-IntuneWin32App` | Gets Win32 apps by ID, by name, or all of them |
| `Set-IntuneWin32App` | Updates a Win32 app's properties and rules from parameters or the `New-IntuneApplication` JSON |
| `Remove-IntuneWin32App` | Deletes Win32 apps (asks first; supports `-WhatIf`) |
| `Add-IntuneWin32AppSupersedence` | Makes a Win32 app supersede (update or replace) other Win32 apps |
| `Add-IntuneWin32AppDependency` | Makes a Win32 app depend on other Win32 apps |
| `New-ApplicationDeploymentGroup` | Generates (and optionally creates in Entra ID) the Available/Required/Test/Phase1 groups |
| `Get-IntunePackagingTool` | Downloads `IntuneWinAppUtil.exe` from Microsoft's GitHub repository and checks its signature |
| `Get-MSIProperty` | Reads the Property table (ProductName, ProductVersion, ProductCode ...) of an MSI |
| `Set-ScriptSignature` | Signs PowerShell files with a PFX code-signing certificate |
| `Invoke-Executable` | Runs an executable and returns its exit code and output |
| `Start-DownloadFile` | Deprecated. Downloads a file to a folder |
| `New-PackageJSON` | Deprecated. Writes package metadata JSON for a source folder |

Aliases kept for earlier versions: `Get-MSIProperties`, `New-ApplicationDeploymentGroups`,
`ConvertTo-SignedScript`.

Run `Get-Help <function> -Full` for parameters and examples.

`IntuneWinAppUtil.exe` is stored per user in `%LOCALAPPDATA%\tcs.intune.packaging` (a copy in the
module folder from an earlier version is still used), so the module works when installed for all users.
When it is missing, the packaging commands ask before downloading release v1.8.6 (use `-AllowDownload`
to skip the question), and a download is refused unless it is signed by Microsoft.

APF packages are installed in Intune with
`%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File Intune-I-MainInstaller.ps1`
(uninstall: the same with `-Uninstall`); `New-APFDeployment` and `New-APFConfigDeployment` print these
commands. `sysnative` makes the 32-bit Intune Management Extension start the 64-bit Windows PowerShell.

## Configuration

Settings are handled by tcs.core. The settings file is
`<ApplicationData>/PowerShell/Config/tcs.intune.packaging/Module.Config.json` and is created with
the defaults the first time the module loads. Change it with `Set-ModuleConfig`:

```powershell
Set-ModuleConfig -ModuleName tcs.intune.packaging -UpdateWarning $false   # no update warnings
Set-ModuleConfig -ModuleName tcs.intune.packaging -Telemetry $false       # no telemetry
```

| Setting | Default | Meaning |
| --- | --- | --- |
| `UpdateWarning` | `true` | Warn on import when a newer version is in the PowerShell Gallery (checked at most once a day) |
| `UpdateCheckIntervalHours` | `24` | How often the gallery is checked |
| `Telemetry` | `true` | Send anonymous usage telemetry |

Environment variables `TCS_TELEMETRY_OPTOUT=1` and `TCS_SKIP_UPDATE_CHECK=1` turn telemetry and
the update check off for every tcs module; `TCS_CONFIG_ROOT` moves the settings folder.

## Privacy and telemetry

tcs modules send anonymous usage telemetry to help find failing commands. Telemetry is on by
default and a notice is shown the first time a module is loaded. Nothing is sent until a
telemetry endpoint is configured.

Each event contains: time (UTC), module and command name, module version, duration, success,
the exception **type** on failure, PowerShell version and edition, OS family, PowerShell host
name, and a random installation ID created on first use.

It **never** contains: user names, machine names, file paths, hardware serial numbers, IP-based
identifiers, command arguments or error messages.

Turn it off with `Set-ModuleConfig -ModuleName tcs.intune.packaging -Telemetry $false`, or for all
tcs modules with the environment variable `TCS_TELEMETRY_OPTOUT=1`.

### Publishing to Intune

`New-IntuneWin32Application` and `Publish-IntuneAppPackage` use Microsoft Graph v1.0: they create the
`win32LobApp`, create a content version and content file, upload the encrypted content from the
`.intunewin` file to the Azure Storage URI in blocks, commit it with the encryption information from
`Detection.xml` and set the app's `committedContentVersion`. Detection and requirement rules come from
`New-IntuneWin32Rule`.

`Publish-IntuneAppPackage` then assigns the app (from the JSON file or its `-Assignment*` parameters)
with the `assign` action, and `Add-IntuneWin32AppSupersedence` / `Add-IntuneWin32AppDependency` use
`updateRelationships`. Both use the Graph beta endpoint: assignment filters and app relationships are
not in v1.0.

```powershell
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All
$rule = New-IntuneWin32Rule -RuleParentType detection -RuleType FileOrFolder -Path 'C:\Program Files\MyApp' -FileOrFolderName 'MyApp.exe' -OperationType exists
New-IntuneWin32Application -Name 'MyApp' -Description 'My app' -Publisher 'Contoso' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'setup.exe /U' -Rules $rule -IntuneWinFilePath .\setup.intunewin
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Report security issues as described in [SECURITY.md](SECURITY.md).

## Licence

GNU General Public License v3.0; see [LICENSE](LICENSE).

## Author

**Nigel Tatschner** - TheCodeSaiyan ([@ntatschner](https://github.com/ntatschner))
