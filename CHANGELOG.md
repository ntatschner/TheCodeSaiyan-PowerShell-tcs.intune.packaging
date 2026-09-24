# Changelog

All notable changes to `tcs.intune.packaging` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-09-24

### Security
- APF detection scripts: the package name was inserted into a double-quoted string
  (`$AppName = "##NAME_TEMPLATE"`), so a name containing `"` or `$(...)` became code in a script that
  runs as SYSTEM. The placeholders are now single-quoted and values are inserted with `'` doubled;
  the filled-in script is parsed before it is written.
- APF package names are validated before they are used as folder names: `.`, `..`, path separators,
  wildcard characters (`[` `]`) and characters Windows does not allow in file names are rejected, and
  the package folder must be a direct child of the destination folder. Folders are deleted with
  `-LiteralPath`.
- `Get-IntunePackagingTool` refuses a downloaded `IntuneWinAppUtil.exe` unless it has a valid
  Authenticode signature from Microsoft Corporation (Windows). The new `-ExpectedSha256` also checks
  the hash; it is required where signatures cannot be checked.
- `New-IntuneWin32AppPackage` and `New-IntuneApplication` no longer download `IntuneWinAppUtil.exe`
  without asking; use the new `-AllowDownload` to download without the question.

### Added
- Assignments: `Publish-IntuneAppPackage` (and `New-IntuneApplication -Publish`) assign the app as set
  by `AssignmentType`, `AssignmentGroup`, the new `AssignmentIntent` (required, available or
  uninstall) and `FilterRuleType`/`FilterRule` (an existing assignment filter by name or ID). These
  come from the JSON file or from new `Publish-IntuneAppPackage` parameters; `-NoAssignment` skips
  it. Groups can be given by ID or display name. Existing assignments are kept.
- `Get-IntuneWin32App`, `Set-IntuneWin32App`, `Remove-IntuneWin32App`,
  `Add-IntuneWin32AppSupersedence`, `Add-IntuneWin32AppDependency` and `Get-IntuneWinPackageInfo`.
- `Get-IntunePackagingTool -ExpectedSha256`; `-AllowDownload` on `New-IntuneWin32AppPackage` and
  `New-IntuneApplication`.

### Changed
- `ConvertTo-SignedScript` is renamed to `Set-ScriptSignature`; `ConvertTo-SignedScript` remains as
  an alias.
- `Publish-IntuneAppPackage -Force` also updates the existing app's properties (names, notes and
  version, command lines, install experience, logo, rules, setup file) from the JSON file after the
  new content is committed; before, only the content was replaced.
- The APF commands print install commands that start the 64-bit Windows PowerShell from the 32-bit
  Intune Management Extension:
  `%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File Intune-I-MainInstaller.ps1`
  (and `-Uninstall`). The template READMEs, which said `-ExecutionPolicy Bypass`, and the about help
  now give the same commands. (`New-IntuneApplication`/`Publish-IntuneAppPackage` use the command
  lines you pass; `New-PackageJSON` has none.)
- `New-ApplicationDeploymentGroup -CreateGroups` returns one object per created or existing group
  (with `Id` and `Status`) instead of status strings; progress is verbose output. Administrative
  unit and member failures are errors instead of warnings. The command stays in this module; moving
  it to another tcs module is a later decision.
- `New-IntuneWin32AppPackage` reports failures as errors instead of warnings (missing folders, setup
  file or tool and tool failures are terminating; an existing package without `-Force` is a
  non-terminating error) and telemetry records them as failures. `Name`, `FileName`, `SetupFile` and
  `UnencryptedContentSize` now always come from the package's `Detection.xml` (the optional
  IntuneWin32App module is no longer used), so `FileName` is `IntunePackage.intunewin`. The tool
  runs with redirected output instead of a separate window.
- `IntuneWinAppUtil.exe` is run by one shared private helper for all packaging commands; automatic
  downloads use release v1.8.6 (the APF commands used the latest release).
- Byte-identical template scripts (`Write-DeploymentLog.ps1` and two detection scripts) are kept once
  in `Public/Templates/_shared` and copied into packages when they are built. Packages contain the
  same files as before.
- `New-IntuneApplication` no longer writes its command options (`Publish`, `Overwrite`, `NoJson`,
  `NoIntuneWin`, `NoCleanUp`, `IntuneToolsPath`, `AllowDownload`) into the JSON file.
- `Invoke-Executable` stays exported for now.

### Deprecated
- `New-PackageJSON` (nothing reads its output; `Publish-IntuneAppPackage` reads the
  `New-IntuneApplication` JSON) and `Start-DownloadFile` (not used by the module) write a
  deprecation warning and may be removed in a future version.

### Fixed
- `New-APFConfigDeployment` with pipeline input read its dynamic parameters in `begin`, before
  pipeline binding: the name was empty, so the destination folder itself became the package folder
  and confirming the overwrite deleted it. The parameters are now read per input object.
- Declining the overwrite prompt in `New-APFConfigDeployment` carried on building the package in the
  existing folder; the deployment is now skipped with a warning, as in `New-APFDeployment`.
- `New-IntuneApplication` with several source files copied folders without their contents, and left
  its staging folder in the output folder unless `-Publish` was used. Folders are now copied
  recursively to a temporary staging folder that is always removed.
- `New-IntuneApplication -Publish` with `-NoJson` or `-NoIntuneWin` is rejected before any file is
  written, and assignment settings are checked before anything is built.
- `New-IntuneWin32AppPackage` checked for the tool with `-or` where `-and` was needed, so a tool that
  only a literal path test found was downloaded again.
- `New-ApplicationDeploymentGroup` treated a failed group lookup as "the group does not exist" and
  created the group, possibly as a duplicate; the group is now skipped with an error.
- The quoted paths passed to `IntuneWinAppUtil.exe` no longer end with a backslash, which escaped the
  closing quote.

### Removed
- The unused private helpers `New-Win32ApplicationInfo`, `New-Win32InstallExperience`,
  `New-Win32Installation`, `New-Win32Requirement` and `New-Win32ReturnCode` and their tests.

## [0.4.1] - 2026-09-24

### Fixed
- Restored the hand-written `about_tcs.intune.packaging` help topic. The shared docs workflow had replaced it with the PlatyPS placeholder.

## [0.4.0] - 2026-09-24

### Added
- Every exported command now reports anonymous usage telemetry through tcs.core
  (`Invoke-TelemetryCollection` Start and End events, with the exception type on failure):
  `ConvertTo-SignedScript`, `Get-IntunePackagingTool`, `Invoke-Executable`,
  `New-ApplicationDeploymentGroup`, `New-IntuneApplication`, `New-IntuneWin32AppPackage`,
  `New-IntuneWin32Rule`, `New-PackageJSON` and `Start-DownloadFile` join the commands that already
  reported it. Command behaviour, output and `-WhatIf` handling are unchanged; telemetry is still
  off with `Set-ModuleConfig -Telemetry $false` or `TCS_TELEMETRY_OPTOUT=1`.
- A test that fails when an exported command does not report telemetry, and telemetry behaviour
  tests for `New-IntuneWin32Rule`, `New-PackageJSON` and `Start-DownloadFile`.
- `.github/scripts/module-smoke-tests.ps1`, run by the shared CI validation: imports the module
  offline, checks the exported commands against the manifest and exercises `New-IntuneWin32Rule`,
  `New-PackageJSON` and `New-ApplicationDeploymentGroup`.
- `.github/PUBLISHING.md`, describing the release process, including that the publish workflow must
  be started manually on the `v<version>` tag created by the tag workflow.

## [0.3.0] - 2026-09-24

### Breaking
- Requires tcs.core 0.3.0 or later (new configuration, telemetry and update-check API).
- `Get-MSIProperties` is renamed to `Get-MSIProperty` and `New-ApplicationDeploymentGroups` to
  `New-ApplicationDeploymentGroup` (singular nouns); the old names remain as aliases.
- The function in `New-IntuneWin32Rule.ps1` was named `New-Win32Rule` and was never exported; it is
  now `New-IntuneWin32Rule` as listed in the manifest.
- `Convert-ModuleNameAndReferences` was listed in the manifest but never existed; removed.
- `New-APFConfigDeployment -ConfigurationType` is mandatory.
- `New-IntuneWin32Application` now creates the app and uploads its content. `InstallCommandLine`,
  `UninstallCommandLine` and `Rules` (with a detection rule) are mandatory for a new app; `Owner`,
  `Developer` and `Version` are optional (the version is added to the notes, because Graph v1.0 has no
  version property for Win32 apps); `MinimumSupportedWindowsRelease` is no longer sent unless given;
  the default restart behaviour is `basedOnReturnCode`. Only `Microsoft.Graph.Authentication` is needed.
- `New-IntuneWin32Rule` returns rules with the Microsoft Graph property names (registry rules use
  `keyPath`, `operationType` exists/doesNotExist/string/integer/version, and so on); MSI rules are
  detection-only.
- `New-IntuneApplication -Publish` publishes the package and then removes the JSON and .intunewin
  files unless `-NoCleanUp` is used.
- `IntuneWinAppUtil.exe` is downloaded to `%LOCALAPPDATA%\tcs.intune.packaging` instead of the module
  folder or the current directory.
- `Get-IntunePackagingTool`, `New-PackageJSON` and `New-IntuneApplication` now return the files they
  create; `Invoke-Executable` also returns `StandardOutput` and `StandardError`.
- `Start-DownloadFile` uses `Invoke-WebRequest` and throws when the download fails.
- The stale `en-US/tcs.intune.packaging-help.xml` is removed; help comes from comment-based help.

### Added
- Publishing to Intune with Microsoft Graph v1.0: `New-IntuneWin32Application` and
  `Publish-IntuneAppPackage` create the Win32 app, create a content version and file, upload the
  encrypted `.intunewin` content to Azure Storage in blocks (renewing the SAS URI for long uploads),
  commit it with the encryption information from `Detection.xml` and set `committedContentVersion`.
  `Publish-IntuneAppPackage -Force` uploads a new content version to an existing app.
- `New-APFConfigDeployment` types `Script-App` (your script, system context), `Script-User` (your
  script, user context) and `Custom` (placeholder script) with a new `script` installer template.
- GPL-3.0 `LICENSE` and `LicenseUri` in the manifest.
- Pester tests for every exported function (cross-platform where possible, Windows-only parts skipped
  elsewhere), `tests/Module.Tests.ps1` (manifest, exports, help, PSScriptAnalyzer, no pipeline output
  on import) and `tests/Templates.Tests.ps1`.
- CI: lint job that fails on warnings, Pester on Windows PowerShell 5.1 and PowerShell 7 (Windows)
  with pinned Pester 5.7.1 / PSScriptAnalyzer 1.23.0.
- `PSScriptAnalyzerSettings.psd1` (same rules as tcs.core).
- `-WhatIf`/`-Confirm` support for the functions that create files, groups or signatures.
- Repository standards: `.editorconfig`, `.gitattributes`, `.gitignore`, `CONTRIBUTING.md`,
  `SECURITY.md`, CODEOWNERS, Dependabot, issue and pull request templates.

### Fixed
- The module loader dot-sourced every `.ps1` under `Public/Templates` (installer scripts) into the
  module; only the top level of `Public/` and `Private/` is loaded now.
- The module could not be imported on Windows PowerShell 5.1: `Classes/intune.package.ps1` and
  `New-IntuneWin32Application.ps1` required PowerShell 7 (`#Requires -PSEdition Core`,
  `IValidateSetValuesGenerator`) and `#Requires -Modules` made the import fail without Microsoft.Graph.
  The ValidateSet class is replaced by an argument completer.
- Telemetry uses the tcs.core 0.3.0 pattern (no placeholder URI, no per-call `Get-ModuleConfig`,
  every Start has an End); the update check result no longer leaks to the pipeline on import.
- `Get-IntunePackagingTool` called `exit` on failure, closing the caller's PowerShell session.
- `ConvertTo-SignedScript` signed every file once per input file, used `Get-PfxCertificate -Password`
  (not available in Windows PowerShell 5.1) and tried to `Install-Module` a built-in module.
- `Invoke-Executable` could hang when a process wrote more output than the pipe buffer holds.
- `New-APFDeployment` and `New-APFConfigDeployment` placed `[CmdletBinding()]` inside `param()`, so
  `-WhatIf`/`-Confirm` did not exist.
- `New-APFConfigDeployment`: `-CLIApp $false` was treated as `$true`; `-RegistryValue` was never
  written to the CSV file; `StandAlone-Exe`, `WindowsFeature` and `Standalone-Application` failed
  setting configuration keys missing from the templates (and `StandAlone-Exe` wrote the executable
  name to a key the installer does not read); `WindowsFeature` recorded a CSV name the installer does
  not use; creating a `.intunewin` used an undefined folder; `Standalone-Application` copied folders
  without their contents.
- `New-IntuneApplication`: the default description was built before `Publisher`/`Version`/`Developer`
  were bound; passing `-Publisher`, `-Version` etc. failed with "Item has already been added"; a
  missing main installer among several source files was not detected; `break` in `begin` could stop
  the caller's loop; paths with spaces broke the `IntuneWinAppUtil.exe` call.
- `New-ApplicationDeploymentGroup` used a non-existent `-DirectoryObjectId` parameter of
  `Add-EntraGroupMember` (now `-MemberId`) and did not escape quotes in the group filter.
- `New-IntuneWin32Rule`: file rules never got their defaults (`'file'` vs `'FileOrFolder'`), dynamic
  parameters were read from undefined variables (MSI `-AutoDetect` never worked) and common
  parameters were copied into the rule.
- `New-IntuneWin32AppPackage` called `Get-IntuneWin32AppMetaData`, which is not part of this module.
- `Test-IntuneLogoImage` did not load System.Drawing on Windows PowerShell 5.1, rejected `.jpeg` and
  its `$true` result leaked into `New-IntuneApplication` output.
- Installer templates: the Registry installer and several pre/post scripts built the log name from a
  `filename` setting their configuration does not have (the scripts stopped with a null error);
  Registry used an undefined `$FullKayPath`, the wrong CSV column for the value type, never saved its
  results or configuration (so detection always failed) and the Registry detection used an undefined
  variable; `$(if ... { } { })` without `else` produced an invalid storage path; the WindowsFeatures
  configuration had no `target`, so its detection never succeeded; pre-install scripts logged
  "Inside Post-Install script".
- Removed `ScriptsToProcess` from the manifest (it double-loaded `intune.package.ps1`), replaced the
  wildcard `FunctionsToExport` with an explicit list and fixed the `HelpInfoURI` placeholder.
- Removed `Config.ps1`, which would write `Config.psd1` into the module folder, and unused
  `Colors.ps1`; removed stale Authenticode signature blocks from edited files.

### Removed
- Duplicate private copies of `Get-IntunePackagingTool` and `New-Win32Rule`, and the unused,
  non-functional private `New-Win32JSON`.
- Per-file `Describe -Tags 'PSSA'` test blocks and their `PSScriptAnalyzerSettings.psd1` files.
- `TEST.json` debug artifact from `Private/`.

## [0.2.10] - 2025-01-01

### Added
- Support for specifying group members for Available, Required, Test, and Phase1 groups in `New-ApplicationDeploymentGroups`
