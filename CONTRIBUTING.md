# Contributing to tcs.intune.packaging

tcs.intune.packaging builds on [tcs.core](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core)
(configuration, telemetry, update checks and dynamic parameters).

## Getting started

Requirements: Windows with Windows PowerShell 5.1 or PowerShell 7, tcs.core 0.3.0 or later,
Pester 5.7.1 and PSScriptAnalyzer 1.23.0.

```powershell
Install-Module tcs.core -MinimumVersion 0.3.0 -Scope CurrentUser
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -SkipPublisherCheck
Install-Module PSScriptAnalyzer -RequiredVersion 1.23.0 -Scope CurrentUser

# Tests (module and repository-wide)
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester -Path ./modules/tcs.intune.packaging, ./tests

# Lint exactly as CI does (warnings fail the build; Pester files are excluded)
Invoke-ScriptAnalyzer -Path ./modules/tcs.intune.packaging -Recurse -Severity Error, Warning -Settings ./PSScriptAnalyzerSettings.psd1 |
    Where-Object { $_.ScriptName -notlike '*.Tests.ps1' }
```

## Layout

| Path | Contents |
| --- | --- |
| `modules/tcs.intune.packaging/Public/` | Exported functions, one per file, named after the function |
| `modules/tcs.intune.packaging/Private/` | Internal helpers (not exported) |
| `modules/tcs.intune.packaging/Public/Templates/` | APF installer scripts copied into packages; **not** loaded into the module |
| `modules/tcs.intune.packaging/*/Tests/` | Pester tests, `<Function>.Tests.ps1` |
| `tests/` | Module-wide tests (manifest, exports, help, PSScriptAnalyzer, templates) |

Every file in `Public/` (top level only) must also be listed in `FunctionsToExport` in
`tcs.intune.packaging.psd1`; `tests/Module.Tests.ps1` checks this.

## Standards

- **Platform:** the module targets Windows (Windows PowerShell 5.1 and PowerShell 7). Avoid
  PS7-only syntax (`??`, `?:`, `&&`, `ForEach-Object -Parallel`) and .NET Core-only APIs. Keep
  logic that does not need Windows testable on any platform (use `Join-Path`, not backslashes).
- **Style:** 4-space indentation, `CmdletBinding()` on every function, approved verbs, singular
  nouns, full command names (no aliases). PSScriptAnalyzer runs with `PSScriptAnalyzerSettings.psd1`
  and **warnings fail the build**. Suppress a rule only with a written justification.
- **State-changing functions** (`New-`, `Set-`, `Remove-` ...) support `-WhatIf`/`-Confirm`.
- **Help:** every exported function has comment-based help with a synopsis, description,
  every parameter and at least one example.
- **Tests:** new behaviour and bug fixes come with Pester tests. Tests must not touch the real
  user profile, Intune or the network: set `TCS_CONFIG_ROOT` to `$TestDrive` and mock external calls
  (`Mock -ModuleName tcs.intune.packaging`).
- **Templates:** the scripts in `Public/Templates` run on managed devices. Keep them compatible with
  Windows PowerShell 5.1 and keep `config.installer.json` keys in step with `New-APFDeployment`
  and `New-APFConfigDeployment`.
- **Versioning:** [Semantic Versioning](https://semver.org). Record changes in `CHANGELOG.md`.

## Releasing

1. Update `ModuleVersion` in `tcs.intune.packaging.psd1` and `CHANGELOG.md`, open a pull request
   and merge it to `main`.
2. CI creates the `vx.y.z` tag when the manifest version is newer than the latest tag, and the tag
   triggers publishing to the PowerShell Gallery.
