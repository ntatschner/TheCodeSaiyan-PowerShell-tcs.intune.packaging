# APF script package

Used by `New-APFConfigDeployment` for the `Script-App`, `Script-User` and `Custom` configuration types.

| File | Purpose |
| --- | --- |
| `Intune-I-MainInstaller.ps1` | Install command. Runs the pre-install script, the deployment script (`scriptfile` in `config.installer.json`) and the post-install script; each must exit with 0. Use `-Uninstall` for the uninstall command: the same scripts run with `-Uninstall`. |
| `Intune-D-Detection.ps1` | Detection script. Detects the package when the saved configuration has the required version or later. |
| `Intune-Custom.ps1` | Placeholder deployment script for the `Custom` type. |
| `config.installer.json` | Name, version, target (`system` or `user`), deployment script and included files. |

The installed configuration is saved to `%ProgramFiles(x86)%\APF\AppConfigs` for `system`
packages and to `%APPDATA%\APF\AppConfigs` for `user` packages (run the Intune app in the user
context for `Script-User`). Logs are written to the `APF\UserLogs` folder in the same location.

Intune install command:
`%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File Intune-I-MainInstaller.ps1`
(uninstall: the same with `-Uninstall`). The Intune Management Extension is a 32-bit process;
`sysnative` makes it start the 64-bit Windows PowerShell. `New-APFConfigDeployment` prints the same commands.
