# Changelog

All notable changes to `tcs.intune.packaging` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Removed `ScriptsToProcess` from manifest (was double-loading `intune.package.ps1` — psm1 Classes block handles this)
- Replaced wildcard `FunctionsToExport = '*'` with explicit function list
- Fixed `HelpInfoURI` placeholder to real URL
- Added `-Recurse` to `Public`, `Private`, and `Classes` discovery in psm1

### Added
- `PSScriptAnalyzerSettings.psd1` — enforced linting rules for consistent code style

### Removed
- `TEST.json` debug artifact from `Private/`

## [0.2.10] - 2025-01-01

### Added
- Support for specifying group members for Available, Required, Test, and Phase1 groups in `New-ApplicationDeploymentGroups`
