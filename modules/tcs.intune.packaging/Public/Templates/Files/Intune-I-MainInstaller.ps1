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
$StorageFolderName = "Files"
$StorageFolderFullPath = Join-Path -Path $APFFullBase -ChildPath "$StorageFolderBase\$StorageFolderName\$($InstallConfig.directory)"
$InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
$LogName = "APF_$($InstallConfig.name)_Files.log"
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

if ([string]::IsNullOrEmpty($InstallConfig.directory)) {
    Write-DeploymentLog -Message "Directory parameter empty, breaking.." -MessageType "Error" -LogPath $LoggingPath
    exit 1
}

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
        if ($Uninstall) {
            Start-Process powershell.exe -ArgumentList "-File `"$PSScriptRoot\$($InstallConfig.precommandfile)`" -Uninstall" -Wait -NoNewWindow -ErrorAction Stop
        }
        else {
            Start-Process powershell.exe -ArgumentList "-File `"$PSScriptRoot\$($InstallConfig.precommandfile)`"" -Wait -NoNewWindow -ErrorAction Stop
        }
    }
    Catch {
        Write-DeploymentLog -Message "Failed to run pre-install script with error: $_" -MessageType "Error" -LogPath $LoggingPath
        exit 1
    }
}

if ($Uninstall) {
    Write-DeploymentLog -Message "Removing package: $($InstallConfig.name), Version: $($InstallConfig.version)" -MessageType "Info" -LogPath $LoggingPath
    Write-DeploymentLog -Message "Imported the following configuration: `n$($InstallConfig | ConvertTo-Json -Depth 5)" -MessageType "Info" -LogPath $LoggingPath

    if (Test-Path -Path $StorageFolderFullPath) {
        try {
            Write-DeploymentLog -Message "Removing file(s) $($InstallConfig.files)." -MessageType "Info" -LogPath $LoggingPath
            if ([string]::IsNullOrEmpty($InstallConfig.files) -eq $false) {
                Write-DeploymentLog -Message "Removing files: $($InstallConfig.files -Replace ',', ' ,')." -MessageType "Info" -LogPath $LoggingPath
                foreach ($a in $($InstallConfig.files -Split ',')) {
                    Write-DeploymentLog -Message "Removing file: $($a)." -MessageType "Info" -LogPath $LoggingPath
                    try {
                        $Item = Get-ChildItem -Path $a
                        Remove-Item -Path $Item -ErrorAction Stop
                    } catch {
                        Write-DeploymentLog -Message "Failed to remove file: $($a)." -MessageType "Warning" -LogPath $LoggingPath
                    }
                }
            }
            try {
                Write-DeploymentLog -Message "Removing directory: $($InstallConfig.directory)." -MessageType "Info" -LogPath $LoggingPath
                Remove-Item -Path $StorageFolderFullPath -Recurse -ErrorAction Stop
            } catch {
                Write-DeploymentLog -Message "Failed to remove directory: $($InstallConfig.directory)." -MessageType "Error" -LogPath $LoggingPath
                exit 1
            }
            Write-DeploymentLog -Message "Successfully removed directory: $($InstallConfig.directory)." -MessageType "Info" -LogPath $LoggingPath
            Write-DeploymentLog -Message "Uninstall completed successfully" -MessageType "Info" -LogPath $LoggingPath

            if ($ExistingConfig -eq $true) {
                Remove-Item -Path "$ConfigBase\$APFBase\AppConfigs\$($InstallConfig.name)_config.installer.json" -Force -Confirm:$false
            }
        }
        catch {
            Write-DeploymentLog -Message "Failed to remove deployed files: $($InstallConfig.files), exiting.." -MessageType "Error" -LogPath $LoggingPath
        }
    }
    else {
        Write-DeploymentLog -Message "Couldn't find the deployed files $($InstallConfig.files), exiting.." -MessageType "Error" -LogPath $LoggingPath
        exit 1
    }

    $Script:TimeTaken = $(Get-Date) - $StartTime
    Write-DeploymentLog -Message "Uninstallation of $($InstallConfig.name), Version $($InstallConfig.version) took $($TimeTaken.ToString('hh\:mm\:ss\.fff'))" -MessageType "Info" -LogPath $LoggingPath
    exit 0
}
else {
    Write-DeploymentLog -Message "Starting installation of $($InstallConfig.name), Version $($InstallConfig.version)" -MessageType "Info" -LogPath $LoggingPath
    # Log the config import
    Write-DeploymentLog -Message "Imported the following configuration: `n$($InstallConfig | ConvertTo-Json -Depth 5)" -MessageType "Info" -LogPath $LoggingPath
    # Install the application
    Write-DeploymentLog -Message "Installing $($InstallConfig.name), Version $($InstallConfig.version)." -MessageType "Info" -LogPath $LoggingPath

    if ((Test-Path -Path $StorageFolderFullPath) -eq $false) {
        Write-DeploymentLog -Message "Couldn't find storage folder: $($StorageFolderName), creating now." -MessageType "Info" -LogPath $LoggingPath
        try {
            New-Item -Path $StorageFolderFullPath -ItemType Directory -ErrorAction Stop
        }
        catch {
            Write-DeploymentLog -Message "Failed to create storage folder $($StorageFolderName), breaking.." -MessageType "Error" -LogPath $LoggingPath
            exit 1
        }
    }
    if (Test-Path -Path $(Join-Path -Path $StorageFolderFullPath)) {
        Write-DeploymentLog -Message "Removing existing folder $($StorageFolderFullPath)" -MessageType "Warning" -LogPath $LoggingPath
        try {
            Remove-Item -Path $(Join-Path -Path $StorageFolderFullPath) -Confirm:$false -ErrorAction Stop
        }
        catch {
            Write-DeploymentLog -Message "Failed removing existing folder $($StorageFolderFullPath), breaking..." -MessageType "Error" -LogPath $LoggingPath
            exit 1
        }
    }
    else {
        Write-DeploymentLog -Message "Copying files to storage folder $($StorageFolderFullPath)" -MessageType "Info" -LogPath $LoggingPath
        try {
            
            if ([string]::IsNullOrEmpty($InstallConfig.files) -eq $false) {
                Write-DeploymentLog -Message "Copying files: $($InstallConfig.files -Replace ',', ' ,')." -MessageType "Info" -LogPath $LoggingPath
                foreach ($a in $($InstallConfig.files -Split ',')) {
                    Write-DeploymentLog -Message "Copying file: $($a)." -MessageType "Info" -LogPath $LoggingPath
                    try {
                        $Item = Get-ChildItem -Path $a
                        Copy-Item -Path $(Join-Path -Path $PSScriptRoot -ChildPath $a) -Destination $StorageFolderFullPath -ErrorAction Stop
                    } catch {
                        Write-DeploymentLog -Message "Failed to copy file: $($a).`nError:`n$($_.Exception.Message)" -MessageType "Warning" -LogPath $LoggingPath
                    }
                }
            }

            Write-DeploymentLog -Message "Copied complete." -MessageType "Info" -LogPath $LoggingPath
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
        }
        catch {
            Write-DeploymentLog -Message "Failed to copy $($InstallConfig.filename) to storage folder $($StorageFolderFullPath), breaking.." -MessageType "Error" -LogPath $LoggingPath
            Exit 1
        }
    }

    Write-DeploymentLog -Message "Installation of $($InstallConfig.name), Version $($InstallConfig.version) completed successfully" -MessageType "Info" -LogPath $LoggingPath
    $Script:TimeTaken = $(Get-Date) - $StartTime
    Write-DeploymentLog -Message "Installation of $($InstallConfig.name), Version $($InstallConfig.version) took $($TimeTaken.ToString('hh\:mm\:ss\.fff'))" -MessageType "Info" -LogPath $LoggingPath
}
# Check if the post-install script exists

if (-not [string]::IsNullOrEmpty($InstallConfig.postcommandfile)) {
    Write-DeploymentLog -Message "Post-install script found, running $($InstallConfig.postcommandfile)" -MessageType "Info" -LogPath $LoggingPath
    # Run the post-install script
    try {
        if ($Uninstall) {
            Start-Process powershell.exe -ArgumentList "-File `"$PSScriptRoot\$($InstallConfig.postcommandfile)`" -Uninstall -ExitCode $($Process.ExitCode)" -Wait -NoNewWindow -ErrorAction Stop
        }
        else {
            Start-Process powershell.exe -ArgumentList "-File `"$PSScriptRoot\$($InstallConfig.postcommandfile)`"" -Wait -NoNewWindow -ErrorAction Stop
        }
    }
    Catch {
        Write-DeploymentLog -Message "Failed to run post-install script with error: $_" -MessageType "Error" -LogPath $LoggingPath
        exit 1
    }
}
Write-DeploymentLog -Message "APF Completed." -MessageType "Info" -LogPath $LoggingPath
exit 0
