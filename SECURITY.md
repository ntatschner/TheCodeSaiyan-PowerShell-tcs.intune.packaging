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

- `ConvertTo-SignedScript` takes the PFX password as a `SecureString` and never writes it anywhere.
- The installer templates run as SYSTEM or as the signed-in user on managed devices. Review any
  custom code you add to `Intune-Pre-Install.ps1` / `Intune-Post-Install.ps1` accordingly.
- Telemetry (through tcs.core) never sends user names, machine names, paths, hardware identifiers
  or error messages. Report anything that suggests otherwise as a security issue.
