# Security Policy

## Supported versions

Only the latest released version of tcs.intune.packaging receives security fixes.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report them privately through
[GitHub security advisories](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.intune.packaging/security/advisories/new).
Include the affected version, the steps to reproduce and the impact you expect.

You should get a first response within 7 days.

## Scope notes

- `Set-ScriptSignature` (formerly `ConvertTo-SignedScript`) takes the PFX password as a
  `SecureString` and never writes it anywhere.
- `IntuneWinAppUtil.exe` is only downloaded after confirmation (or with `-AllowDownload`) and is
  refused unless it has a valid Authenticode signature from Microsoft Corporation (Windows) and, with
  `Get-IntunePackagingTool -ExpectedSha256`, the expected hash.
- Package names are written into the APF detection scripts as single-quoted strings, so a name cannot
  run as code; names that are not safe folder names are rejected.
- The installer templates run as SYSTEM or as the signed-in user on managed devices. Review any
  custom code you add to `Intune-Pre-Install.ps1` / `Intune-Post-Install.ps1` accordingly.
- Telemetry (through tcs.core) never sends user names, machine names, paths, hardware identifiers
  or error messages. Report anything that suggests otherwise as a security issue.
