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
$StorageFolderName = "config"
$StorageFolderFullPath = Join-Path -Path $APFFullBase -ChildPath "$StorageFolderBase\$StorageFolderName"
$InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
$LogName = "APF_$($InstallConfig.name)_OSConfig.log"
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


Write-DeploymentLog -Message "Starting deployment of $($InstallConfig.name) OSConfig entries, Version $($InstallConfig.version)" -MessageType "Info" -LogPath $LoggingPath
# Log the config import
Write-DeploymentLog -Message "Imported the following configuration: `n$($InstallConfig | ConvertTo-Json -Depth 5)" -MessageType "Info" -LogPath $LoggingPath
    
# Create storage folder if it dosent exist
    
if (-not (Test-Path -Path $StorageFolderFullPath)) {
    Write-DeploymentLog -Message "Creating the APF storage folder" -MessageType "Info" -LogPath $LoggingPath
    New-Item -Path $StorageFolderFullPath -ItemType Directory -Force
}

# Create a local copy of config CSV File
if (Test-Path -Path "$PSScriptRoot\$($InstallConfig.configfile)") {
    Copy-Item -Path $(Join-Path -Path $PSScriptRoot -ChildPath $InstallConfig.configfile) -Destination $(Join-Path -Path $StorageFolderFullPath -ChildPath $InstallConfig.configfile) -Force
    Write-DeploymentLog -Message "Config CSV File copied to $($StorageFolderFullPath)\$($InstallConfig.configfile)" -MessageType "Info" -LogPath $LoggingPath
}
else {
    Write-DeploymentLog -Message "Config CSV File not found" -MessageType "Error" -LogPath $LoggingPath
    exit 1
}
# Process the CSV File to make the config modifications
$ConfigData = Import-Csv -Path $(Join-Path -Path $StorageFolderFullPath -ChildPath $InstallConfig.configfile)
# Add new columns to the CSV File
$ConfigData | Add-Member -MemberType NoteProperty -Name "Result" -Value ""
$ConfigData | Add-Member -MemberType NoteProperty -Name "Error" -Value ""
Write-DeploymentLog -Message "Processing the Config CSV File, found $($ConfigData.Count) entries" -MessageType "Info" -LogPath $LoggingPath
# Loop through the CSV File and make the config modifications
foreach ($ConfigEntry in $ConfigData) {
    Write-DeploymentLog -Message "Processing $($ConfigEntry.action) of OSConfig: $($ConfigEntry.settingtype)." -MessageType "Info" -LogPath $LoggingPath
    if ($Uninstall) {
        $ConfigEntry.action = "Remove"
    }
    try {
        switch -Regex ($ConfigEntry.settingtype) {
            "EnvironmentVariable" {
                switch ($ConfigEntry.action) {
                    "Add" {
                        Write-DeploymentLog -Message "Adding Environment Variable $($ConfigEntry.settingname) with value $($ConfigEntry.settingvalue)" -MessageType "Info" -LogPath $LoggingPath
                        $Pattern = ";?$([regex]::Escape($ConfigEntry.settingvalue))"
                        $CurrentValue = [System.Environment]::GetEnvironmentVariable($ConfigEntry.settingname, [System.EnvironmentVariableTarget]::Machine)
                        $Regex = [regex]::new($Pattern)
                        if (([string]::IsNullOrEmpty($CurrentValue) -eq $false) -or ($Regex.Match($CurrentValue).Success)) {
                            Write-DeploymentLog -Message "Value $($ConfigEntry.settingvalue) already exists in the Environment Variable $($ConfigEntry.settingname)" -MessageType "Info" -LogPath $LoggingPath
                        }
                        else {
                            [System.Environment]::SetEnvironmentVariable($ConfigEntry.settingname, $ConfigEntry.settingvalue, [System.EnvironmentVariableTarget]::Machine)
                        }
                        $ConfigEntry.Result = "Success"
                    }
                    "Remove" {
                        Write-DeploymentLog -Message "Removing Environment Variable $($ConfigEntry.settingname)" -MessageType "Info" -LogPath $LoggingPath
                        $Pattern = ";?$([regex]::Escape($ConfigEntry.settingvalue))"
                        $CurrentValue = [System.Environment]::GetEnvironmentVariable($ConfigEntry.settingname, [System.EnvironmentVariableTarget]::Machine)
                        $Regex = [regex]::new($Pattern)
                        $NewValue = $Regex.Replace($CurrentValue, "") 
                        [System.Environment]::SetEnvironmentVariable($ConfigEntry.settingname, $NewValue, [System.EnvironmentVariableTarget]::Machine)
                        $ConfigEntry.Result = "Success"
                    }
                    "Update" {
                        Write-DeploymentLog -Message "Updating Environment Variable $($ConfigEntry.settingname) with value $($ConfigEntry.settingvalue)" -MessageType "Info" -LogPath $LoggingPath
                        $Pattern = ";?$([regex]::Escape($ConfigEntry.settingvalue))"
                        $CurrentValue = [System.Environment]::GetEnvironmentVariable($ConfigEntry.settingname, [System.EnvironmentVariableTarget]::Machine)
                        $Regex = [regex]::new($Pattern)
                        if ($Regex.Match($CurrentValue).Success) {
                            Write-DeploymentLog -Message "Value $($ConfigEntry.settingvalue) already exists in the Environment Variable $($ConfigEntry.settingname)" -MessageType "Info" -LogPath $LoggingPath
                        }
                        else {
                            $ExistingVariable = [System.Environment]::GetEnvironmentVariable($ConfigEntry.settingname, [System.EnvironmentVariableTarget]::Machine)
                            if ([string]::IsNullOrEmpty($ExistingVariable)) {
                                $MergedValue = $ConfigEntry.settingvalue

                            }
                            else {
                                $MergedValue = "$ExistingVariable;$($ConfigEntry.settingvalue)"
                            }
                            [System.Environment]::SetEnvironmentVariable($ConfigEntry.settingname, $MergedValue, [System.EnvironmentVariableTarget]::Machine)
                        }
                        $ConfigEntry.Result = "Success"
                    }
                    default {
                        $ConfigEntry.Result = "Failed"
                        $ConfigEntry.Error = "Invalid Action"
                    }
                }
            }
            default {
                $ConfigEntry.Result = "Failed"
                $ConfigEntry.Error = "Invalid Setting Type"
            }
        }
    }
    Catch {
        Write-DeploymentLog -Message "Failed to $($ConfigEntry.action) of $($ConfigEntry.settingtype) in $($FullKeyPathWithKey) with error: $_" -MessageType "Error" -LogPath $LoggingPath
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
