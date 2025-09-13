param(
    [switch]$Uninstall
)
# Install application defined in the Intune-I-MainInstaller.json file and run and pre and post installation scripts

# Importing the install configuration json file
$InstallConfig = Get-Content -Path "$PSScriptRoot\config.installer.json" | ConvertFrom-Json

#region Global Variables
$ConfigBase = ${env:ProgramFiles(x86)}
$APFBase = "APF"
$APFFullBase = Join-Path -Path $ConfigBase -ChildPath $APFBase
$StorageFolderBase = "PersistentStorage"
$StorageFolderName = $(if ([string]::IsNullOrEmpty($ConfigBase.name)) { "config" } { "$($ConfigBase.name)" })
$StorageFolderFullPath = Join-Path -Path $APFFullBase -ChildPath "$StorageFolderBase\$StorageFolderName"
$InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
$LogName = "APF_$($InstallConfig.name)_WindowsFeatures.log"
$InvalidChars | % { $LogName = $LogName -replace [regex]::Escape($_), "" }
$LoggingPath = Join-Path -Path (Join-Path -Path $ConfigBase -ChildPath "\$APFBase\UserLogs\") -ChildPath $LogName
$ExistingConfig = $false
$StartTime = Get-Date
#endregion Global Variables

#region Logging function
try {
    Import-Module -Name "$PSScriptRoot\Write-DeploymentLog.ps1" -Force -ErrorAction Stop
}
Catch {
    Write-Host "Failed to import the logging function with error: $_"
    exit 1
}
#endregion Logging Function
Write-DeploymentLog -Message "APF Started." -MessageType "Info" -LogPath $LoggingPath
# Setup Working Directory

# Create config directory if it dosent exist

if (-not (Test-Path -Path "$ConfigBase\$APFBase\AppConfigs")) {
    Write-DeploymentLog -Message "Creating the APF App Configs folder" -MessageType "Info" -LogPath $LoggingPath
    New-Item -Path "$ConfigBase\$APFBase\AppConfigs" -ItemType Directory -Force
}

if (-not (Test-Path -Path "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json")) {
    Write-DeploymentLog -Message "Installer config dosen't exist in the APF App Configs folder" -MessageType "Info" -LogPath $LoggingPath
}
else {
    $ExistingConfig = $true
    $LocalConfig = Get-Content -Path "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json" | ConvertFrom-Json
    if ($LocalConfig -ne $InstallConfig) {
        if (([version]$InstallConfig.version -gt [version]$LocalConfig.version) -and (-not $Uninstall)) {
            Write-DeploymentLog -Message "The installer config is newer than the one in the APF App Configs folder, this installation will upgrade the existing installation" -MessageType "Info" -LogPath $LoggingPath
        }
        elseif (([version]$InstallConfig.version -lt [version]$LocalConfig.version) -and (-not $Uninstall)) {
            Write-DeploymentLog -Message "The installer config is older than the one in the APF App Configs folder, this installation will not be performed" -MessageType "Info" -LogPath $LoggingPath
            exit 0
        }
        elseif (([version]$InstallConfig.version -eq [version]$LocalConfig.version) -and (-not $Uninstall)) {
            Write-DeploymentLog -Message "The version number in the installer config is the same as the one in the APF App Configs folder, check if another value has changed, this installation will not be performed" -MessageType "Info" -LogPath $LoggingPath
            exit 0
        }
    }
    else {
        Write-DeploymentLog -Message "The installer config is the same as the one in the APF Scripts folder, Detection might have failed. Aborting" -MessageType "Info" -LogPath $LoggingPath
        exit 1
    }
}

# Check if the pre-install script exists

if (-not [string]::IsNullOrEmpty($InstallConfig.precommandfile)) {
    Write-DeploymentLog -Message "Pre-install script found, running $($InstallConfig.precommandfile)" -MessageType "Info" -LogPath $LoggingPath
    try {
        Start-Process powershell.exe -ArgumentList "-File `"$PSScriptRoot\$($InstallConfig.precommandfile)`"" -Wait -NoNewWindow -ErrorAction Stop
    }
    Catch {
        Write-DeploymentLog -Message "Failed to run pre-install script with error: $_" -MessageType "Error" -LogPath $LoggingPath
        exit 1
    }
}


Write-DeploymentLog -Message "Starting deployment of $($InstallConfig.name) Windows Feature entries, Version $($InstallConfig.version)" -MessageType "Info" -LogPath $LoggingPath
# Log the config import
Write-DeploymentLog -Message "Imported the following configuration: `n$($InstallConfig | ConvertTo-Json -Depth 5)" -MessageType "Info" -LogPath $LoggingPath
    
# Create storage folder if it dosent exist
    
if (-not (Test-Path -Path $StorageFolderFullPath)) {
    Write-DeploymentLog -Message "Creating the APF storage folder" -MessageType "Info" -LogPath $LoggingPath
    New-Item -Path $StorageFolderFullPath -ItemType Directory -Force
}

# Create a local copy of config CSV File
if (Test-Path -Path "$PSScriptRoot\$($InstallConfig.name)_config.csv") {
    Copy-Item -Path "$PSScriptRoot\$($InstallConfig.name)_config.csv" -Destination "$StorageFolderFullPath\$($InstallConfig.name)_config.csv" -Force
    Write-DeploymentLog -Message "Config CSV File copied to $StorageFolderFullPath\$($InstallConfig.name)_config.csv" -MessageType "Info" -LogPath $LoggingPath
}
else {
    Write-DeploymentLog -Message "Config CSV File not found" -MessageType "Error" -LogPath $LoggingPath
    exit 1
}
# Process the CSV File to make the config modifications
$ConfigData = Import-Csv -Path "$StorageFolderFullPath\$($InstallConfig.name)_config.csv"
# Add new columns to the CSV File
$ConfigData | Add-Member -MemberType NoteProperty -Name "Result" -Value ""
$ConfigData | Add-Member -MemberType NoteProperty -Name "Error" -Value ""
Write-DeploymentLog -Message "Processing the Config CSV File, found $($ConfigData.Count) entries" -MessageType "Info" -LogPath $LoggingPath
# Loop through the CSV File and make the config modifications
foreach ($ConfigEntry in $ConfigData) {
    Write-DeploymentLog -Message "Processing $($ConfigEntry.action) of Windows Feature: $($ConfigEntry.featurename)." -MessageType "Info" -LogPath $LoggingPath
    try {
        $FeatureTest = Get-WindowsOptionalFeature -Online -FeatureName $ConfigEntry.featurename -ErrorAction SilentlyContinue
        switch -Regex ($ConfigEntry.action) {
            "ADD" {
                if ($FeatureTest.state -eq "Enabled") {
                    Write-DeploymentLog -Message "Windows Feature: $($ConfigEntry.featurename) is already enabled" -MessageType "Info" -LogPath $LoggingPath
                    $ConfigEntry.Result = "Success"
                    continue
                }
                else {
                    try {
                        Enable-WindowsOptionalFeature -Online -FeatureName $ConfigEntry.featurename -NoRestart -ErrorAction Stop
                        $ConfigEntry.Result = "Success"
                        if ($FeatureTest.RestartRequired -eq "Possible") {
                            Write-DeploymentLog -Message "Windows Feature: $($ConfigEntry.featurename) enabled, a restart is required" -MessageType "Info" -LogPath $LoggingPath
                            $ConfigEntry.notes = "Restart Required"
                        }
                        else {
                            Write-DeploymentLog -Message "Windows Feature: $($ConfigEntry.featurename) enabled" -MessageType "Info" -LogPath $LoggingPath
                        }
                        Write-DeploymentLog -Message "Successfully performed: $($ConfigEntry.action) on Windows Feature: $($ConfigEntry.featurename)" -MessageType "Info" -LogPath $LoggingPath
                        $ConfigEntry.Result = "Success"
                        Write-DeploymentLog -Message "Successfully performed: $($ConfigEntry.action) on $($FullKeyPath) on Windows Feature: $($ConfigEntry.featurename)" -MessageType "Info" -LogPath $LoggingPath
                    }
                    catch {
                        Write-DeploymentLog -Message "Failed to $($ConfigEntry.action) on Windows Feature: $($ConfigEntry.featurename) with error: $_" -MessageType "Error" -LogPath $LoggingPath
                        $ConfigEntry.Result = "Failed"
                        $ConfigEntry.Error = $_.Exception.Message
                    }
                }
            }
            "REMOVE" {
                if ($FeatureTest.state -eq "Disabled") {
                    Write-DeploymentLog -Message "Windows Feature: $($ConfigEntry.featurename) is already disabled" -MessageType "Info" -LogPath $LoggingPath
                    $ConfigEntry.Result = "Success"
                    continue
                }
                else {
                    try {
                        Disable-WindowsOptionalFeature -Online -FeatureName $ConfigEntry.featurename -NoRestart -ErrorAction Stop
                        $ConfigEntry.Result = "Success"
                        if ($FeatureTest.RestartRequired -eq "Possible") {
                            Write-DeploymentLog -Message "Windows Feature: $($ConfigEntry.featurename) disabled, a restart is required" -MessageType "Info" -LogPath $LoggingPath
                            $ConfigEntry.notes = "Restart Required"
                        }
                        else {
                            Write-DeploymentLog -Message "Windows Feature: $($ConfigEntry.featurename) disabled" -MessageType "Info" -LogPath $LoggingPath
                        }
                        Write-DeploymentLog -Message "Successfully performed: $($ConfigEntry.action) on Windows Feature: $($ConfigEntry.featurename)" -MessageType "Info" -LogPath $LoggingPath
                        $ConfigEntry.Result = "Success"
                        Write-DeploymentLog -Message "Successfully performed: $($ConfigEntry.action) on $($FullKeyPath) on Windows Feature: $($ConfigEntry.featurename)" -MessageType "Info" -LogPath $LoggingPath
                    }
                    catch {
                        Write-DeploymentLog -Message "Failed to $($ConfigEntry.action) on Windows Feature: $($ConfigEntry.featurename) with error: $_" -MessageType "Error" -LogPath $LoggingPath
                        $ConfigEntry.Result = "Failed"
                        $ConfigEntry.Error = $_.Exception.Message
                    }
                }
            }
            default {
                $ConfigEntry.Result = "Failed"
                $ConfigEntry.Error = "Invalid Action"
            }
        }
    }
    Catch {
        Write-DeploymentLog -Message "Failed to $($ConfigEntry.action) of $($ConfigEntry.featurename) in $($FullKeyPathWithKey) with error: $_" -MessageType "Error" -LogPath $LoggingPath
        $ConfigEntry.Result = "Failed"
        $ConfigEntry.Error = $_.Exception.Message
    }
}

if ($ExistingConfig -eq $false) {
    Write-DeploymentLog -Message "Creating the config file for the installed application" -MessageType "Info" -LogPath $LoggingPath
    $InstallConfig | ConvertTo-Json | Set-Content -Path "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json"
}
else {
    # Backup previous config file
    Write-DeploymentLog -Message "Backing up the previous config file for the installed application" -MessageType "Info" -LogPath $LoggingPath
    Copy-Item -Path "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json" -Destination "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json.bak" -Force
    Write-DeploymentLog -Message "Updating the config file for the installed application" -MessageType "Info" -LogPath $LoggingPath
    $InstallConfig | ConvertTo-Json | Set-Content -Path "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json"
}

Write-DeploymentLog -Message "Installation of $($InstallConfig.name), Version $($InstallConfig.version) completed successfully" -MessageType "Info" -LogPath $LoggingPath
$Script:TimeTaken = $(Get-Date) - $StartTime
Write-DeploymentLog -Message "Installation of $($InstallConfig.name), Version $($InstallConfig.version) took $($TimeTaken.ToString('hh\:mm\:ss\.fff'))" -MessageType "Info" -LogPath $LoggingPath

# Check if the post-install script exists

if (-not [string]::IsNullOrEmpty($InstallConfig.postcommandfile)) {
    Write-DeploymentLog -Message "Post-install script found, running $($InstallConfig.postcommandfile)" -MessageType "Info" -LogPath $LoggingPath
    # Run the post-install script
    try {
        Start-Process powershell.exe -ArgumentList "-File `"$PSScriptRoot\$($InstallConfig.postcommandfile)`"" -Wait -NoNewWindow -ErrorAction Stop
    }
    Catch {
        Write-DeploymentLog -Message "Failed to run post-install script with error: $_" -MessageType "Error" -LogPath $LoggingPath
        exit 1
    }
}
Write-DeploymentLog -Message "APF Completed." -MessageType "Info" -LogPath $LoggingPath
exit 0
