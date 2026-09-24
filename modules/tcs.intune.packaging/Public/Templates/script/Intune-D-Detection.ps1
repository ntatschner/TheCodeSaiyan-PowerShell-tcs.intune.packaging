# Intune detection script: the deployment is detected when the configuration saved by
# Intune-I-MainInstaller.ps1 exists and its version is the required version or later.

# Name and version as per config.installer.json
$AppName = '##NAME_TEMPLATE'
$Version = '##VERSION_TEMPLATE'
$APFBase = "APF"

# System deployments save their configuration under Program Files (x86), user deployments under
# the user's roaming profile
$PathsToCheck = @("${env:ProgramFiles(x86)}\$APFBase\AppConfigs\$($AppName)_config.installer.json")
$PathsToCheck += Get-ChildItem -Path "c:\Users\*\AppData\Roaming\$APFBase\AppConfigs\$($AppName)_config.installer.json" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

foreach ($Path in $PathsToCheck) {
    if (Test-Path -Path $Path) {
        $VersionInfo = Get-Content -Path $Path | ConvertFrom-Json
        if ([version]$VersionInfo.version -ge [version]$Version) {
            Write-Output "The deployment is installed with version $($VersionInfo.version) (required $Version) on file $Path"
            exit 0
        }
        Write-Output "The installed version $($VersionInfo.version) is older than the required version $Version on file $Path"
        exit 1
    }
}

# If the script hasn't exited by this point, the configuration file does not exist
Write-Output "The version file does not exist"
exit 1
