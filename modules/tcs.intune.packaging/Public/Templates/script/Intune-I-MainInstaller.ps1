param(
    [switch]$Uninstall
)
# Runs the deployment script named in config.installer.json ('scriptfile') with the pre- and
# post-install scripts, and records the installed configuration for the detection script.

# Importing the install configuration json file
$InstallConfig = Get-Content -Path "$PSScriptRoot\config.installer.json" | ConvertFrom-Json

#region Global Variables
$ConfigBase = if ($InstallConfig.target -eq "user") { $env:APPDATA } else { ${env:ProgramFiles(x86)} }
$APFBase = "APF"
$AppConfigFolder = Join-Path -Path (Join-Path -Path $ConfigBase -ChildPath $APFBase) -ChildPath "AppConfigs"
$AppConfigFile = Join-Path -Path $AppConfigFolder -ChildPath "$($InstallConfig.name)_config.installer.json"
$InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
$LogName = "APF_$($InstallConfig.name)_Script.log"
$InvalidChars | ForEach-Object { $LogName = $LogName -replace [regex]::Escape($_), "" }
$LoggingPath = Join-Path -Path (Join-Path -Path $ConfigBase -ChildPath "\$APFBase\UserLogs\") -ChildPath $LogName
$StartTime = Get-Date
#endregion Global Variables

#region Logging function
try {
    Import-Module -Name "$PSScriptRoot\Write-DeploymentLog.ps1" -Force -ErrorAction Stop
}
catch {
    Write-Error -Message "Failed to import the logging function with error: $_"
    exit 1
}
#endregion Logging Function

# Runs a PowerShell script from the package folder and returns its exit code
function Invoke-PackageScript {
    param(
        [string]$ScriptName,
        [switch]$Uninstall
    )
    $Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path -Path $PSScriptRoot -ChildPath $ScriptName)`""
    if ($Uninstall) {
        $Arguments += " -Uninstall"
    }
    $Process = Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -WorkingDirectory $PSScriptRoot -Wait -NoNewWindow -PassThru -ErrorAction Stop
    return $Process.ExitCode
}

Write-DeploymentLog -Message "APF Started." -MessageType "Info" -LogPath $LoggingPath
Write-DeploymentLog -Message "Imported the following configuration: `n$($InstallConfig | ConvertTo-Json -Depth 5)" -MessageType "Info" -LogPath $LoggingPath

if ([string]::IsNullOrEmpty($InstallConfig.scriptfile) -or -not (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath $InstallConfig.scriptfile))) {
    Write-DeploymentLog -Message "The deployment script '$($InstallConfig.scriptfile)' was not found in the package" -MessageType "Error" -LogPath $LoggingPath
    exit 1
}

if (-not $Uninstall -and (Test-Path -Path $AppConfigFile)) {
    $LocalConfig = Get-Content -Path $AppConfigFile | ConvertFrom-Json
    if ([version]$InstallConfig.version -le [version]$LocalConfig.version) {
        Write-DeploymentLog -Message "Version $($LocalConfig.version) is already installed; version $($InstallConfig.version) will not be installed" -MessageType "Info" -LogPath $LoggingPath
        exit 0
    }
    Write-DeploymentLog -Message "Upgrading from version $($LocalConfig.version) to $($InstallConfig.version)" -MessageType "Info" -LogPath $LoggingPath
}

foreach ($Step in @(
        @{ Name = 'pre-install'; Script = $InstallConfig.precommandfile }
        @{ Name = 'deployment'; Script = $InstallConfig.scriptfile }
        @{ Name = 'post-install'; Script = $InstallConfig.postcommandfile }
    )) {
    if ([string]::IsNullOrEmpty($Step.Script)) {
        continue
    }
    Write-DeploymentLog -Message "Running the $($Step.Name) script $($Step.Script)" -MessageType "Info" -LogPath $LoggingPath
    try {
        $ExitCode = Invoke-PackageScript -ScriptName $Step.Script -Uninstall:$Uninstall
    }
    catch {
        Write-DeploymentLog -Message "Failed to run the $($Step.Name) script with error: $_" -MessageType "Error" -LogPath $LoggingPath
        exit 1
    }
    if ($ExitCode -ne 0) {
        Write-DeploymentLog -Message "The $($Step.Name) script exited with code $ExitCode" -MessageType "Error" -LogPath $LoggingPath
        exit $ExitCode
    }
}

if ($Uninstall) {
    if (Test-Path -Path $AppConfigFile) {
        Remove-Item -Path $AppConfigFile -Force
    }
    Write-DeploymentLog -Message "Uninstallation of $($InstallConfig.name) completed" -MessageType "Info" -LogPath $LoggingPath
}
else {
    if (-not (Test-Path -Path $AppConfigFolder)) {
        $null = New-Item -Path $AppConfigFolder -ItemType Directory -Force
    }
    $InstallConfig | ConvertTo-Json | Set-Content -Path $AppConfigFile
    Write-DeploymentLog -Message "Installation of $($InstallConfig.name), Version $($InstallConfig.version) completed" -MessageType "Info" -LogPath $LoggingPath
}
$TimeTaken = (Get-Date) - $StartTime
Write-DeploymentLog -Message "APF Completed in $($TimeTaken.ToString('hh\:mm\:ss\.fff'))." -MessageType "Info" -LogPath $LoggingPath
exit 0
