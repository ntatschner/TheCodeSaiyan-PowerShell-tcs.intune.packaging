function New-APFDeployment {
    <#
    .SYNOPSIS
        Creates an Application Packaging Framework (APF) deployment package for Intune.

    .DESCRIPTION
        The New-APFDeployment function creates a folder named after the application in DestinationFolder,
        copies the installer and any additional files into it, adds the APF installer scripts from the
        module's Application template and fills in config.installer.json and the detection script.
        Optionally it also wraps the folder into a .intunewin package with IntuneWinAppUtil.exe.

        For MSI files the name and version are read from the MSI when not supplied (Windows only). For
        EXE files the file name and file version are used.

        When the application folder already exists you are asked before it is deleted and recreated;
        when you decline, the folder is left unchanged and a warning is written.

        The name is used as a folder name and is written into the detection script. It must not be
        '.' or '..', contain path separators, wildcard characters ([ ]) or characters that Windows does
        not allow in file names (< > : " | ? *), or end with a space or a dot.

    .PARAMETER Name
        The name of the application. It is written into the exported configuration files and used as the
        folder name. When omitted it is read from the installer file.

    .PARAMETER Version
        The version of the application in the format x.x.x.x. When omitted it is read from the installer file.

    .PARAMETER Target
        The installation context: 'system' or 'user'. Default is 'system'.

    .PARAMETER InstallSwitches
        The command-line switches used to install the application.

    .PARAMETER UninstallSwitches
        The command-line switches used to uninstall the application.

    .PARAMETER UninstallPath
        The path to the uninstall executable or file.

    .PARAMETER Path
        The path to the installer file (.msi or .exe).

    .PARAMETER IncludedFiles
        Paths to additional files to include in the package.

    .PARAMETER DestinationFolder
        The folder in which the application folder is created. Default is the current directory.

    .PARAMETER CreateIntuneWinPackage
        Also creates a .intunewin package in DestinationFolder. IntuneWinAppUtil.exe is downloaded to the
        per-user tool folder (LocalApplicationData\tcs.intune.packaging) after confirmation when it is missing.

    .OUTPUTS
        System.String
        Messages that describe where the package was created and which install commands to use.

    .EXAMPLE
        New-APFDeployment -Path "C:\Installers\MyApp.msi" -Name "MyApp" -Version "1.0.0.0"

        Creates an APF deployment package for MyApp version 1.0.0.0 in the current directory.

    .EXAMPLE
        New-APFDeployment -Path "C:\Installers\Setup.exe" -InstallSwitches "/S" -UninstallSwitches "/U" -DestinationFolder C:\Packages -CreateIntuneWinPackage

        Creates an APF deployment package with custom install and uninstall switches and a .intunewin package.

    .NOTES
        Only MSI and EXE installer files are supported.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(HelpMessage = "The name of the application. `nThis is written in to the exported configuration files. `nIf you do not provide a name, the script will attempt to extract it from the installer file.")]
        [Alias("ApplicationName", "AppName")]
        [string]$Name,

        [Parameter(HelpMessage = "The version of the application. `nThis is written in to the exported configuration files. `nThis should be in the format of x.x.x.x. `nIf you do not provide a version, the script will attempt to extract it from the installer file.")]
        [Alias("ApplicationVersion", "AppVersion")]
        [version]$Version,

        [Parameter(HelpMessage = "The target for the deployment, User context or System context. Default is 'system'.")]
        [ValidateSet("system", "user")]
        [string]$Target = "system",

        [Parameter(HelpMessage = "The switches to use when installing the application.")]
        [string]$InstallSwitches,

        [Parameter(HelpMessage = "The switches to use when uninstalling the application.")]
        [string]$UninstallSwitches,

        [Parameter(HelpMessage = "The path to the uninstall file.")]
        [string]$UninstallPath,

        [Parameter(Mandatory = $true)]
        [Alias("InstallerFile", "SourceFile")]
        [ValidateScript({
                if ($_ -notmatch "\.(msi|exe)$") {
                    throw "Please supply a valid installer file path. Only .msi and .exe files are supported."
                }
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    throw "The file $_ does not exist."
                }
                $true
            })]
        [string]$Path,

        [Parameter(HelpMessage = "Paths to any additional files that need to be included in the installation.")]
        [ValidateScript({
                foreach ($file in $_) {
                    if (-not (Test-Path -Path $file)) {
                        throw "The file $file does not exist."
                    }
                }
                $true
            })]
        [string[]]$IncludedFiles,

        [Parameter(HelpMessage = "The folder where the files will be copied to. Default is the current directory.")]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Container)) {
                    throw "The folder $_ does not exist."
                }
                $true
            })]
        [string]$DestinationFolder = $PWD.Path,

        [Parameter(HelpMessage = "Create a Intune package for the application. Default is false.")]
        [switch]$CreateIntuneWinPackage
    )
    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer

        try {
            $InstallerFile = Get-Item -Path $Path -ErrorAction Stop
            if ($InstallerFile.Extension -eq '.msi') {
                if (-not $Name -or -not $Version) {
                    # Read the application name and version from the MSI file
                    $MSIProperties = Get-MSIProperty -Path $InstallerFile.FullName -ErrorAction Stop
                    if (-not $Name) {
                        $Name = $MSIProperties.ProductName
                    }
                    if (-not $Version) {
                        $Version = [version]$MSIProperties.ProductVersion
                    }
                }
            }
            else {
                if (-not $Name) {
                    $Name = $InstallerFile.BaseName
                }
                if (-not $Version) {
                    $FileVersion = $InstallerFile.VersionInfo.FileVersion
                    $ParsedVersion = $null
                    if ([string]::IsNullOrEmpty($FileVersion) -or -not [version]::TryParse(($FileVersion -replace ',\s*', '.' -replace '\s.*$', ''), [ref]$ParsedVersion)) {
                        throw "The version could not be read from '$($InstallerFile.Name)'. Specify it with -Version."
                    }
                    $Version = $ParsedVersion
                }
            }
            if ([string]::IsNullOrEmpty($Name)) {
                throw 'The application name could not be determined. Specify it with -Name.'
            }

            # Create the application folder; Name is validated and the folder must be a subfolder of DestinationFolder
            $AppFolder = Get-PackageFolderPath -DestinationFolder $DestinationFolder -Name $Name
            if (-not $PSCmdlet.ShouldProcess($AppFolder, 'Create APF deployment package')) {
                Invoke-TelemetryCollection @TelemetryArgs -Stage End
                return
            }
            if (Test-Path -LiteralPath $AppFolder) {
                if (-not (Confirm-FolderOverwrite -Path $AppFolder)) {
                    Write-Warning "The folder '$AppFolder' already exists and was not changed."
                    Invoke-TelemetryCollection @TelemetryArgs -Stage End
                    return
                }
                Remove-Item -LiteralPath $AppFolder -Recurse -Force -ErrorAction Stop
            }
            $null = New-Item -Path $AppFolder -ItemType Directory -ErrorAction Stop

            # Copy the installer file and any additional files to the application folder
            Copy-Item -LiteralPath $InstallerFile.FullName -Destination $AppFolder -ErrorAction Stop
            foreach ($File in $IncludedFiles) {
                Copy-Item -Path $File -Destination $AppFolder -Recurse -ErrorAction Stop
            }
            # Copy the template files to the application folder
            Copy-APFTemplate -Template 'Application' -Destination $AppFolder -Exclude '*.md'

            # Update the template files with the application details
            $ConfigPath = Join-Path -Path $AppFolder -ChildPath 'config.installer.json'
            $MainConfig = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $MainConfig.name = $Name
            $MainConfig.version = $Version.ToString()
            $MainConfig.filename = $InstallerFile.Name
            $MainConfig.target = $Target
            $MainConfig.installSwitches = [string]$InstallSwitches
            $MainConfig.uninstallSwitches = [string]$UninstallSwitches
            $MainConfig.uninstallPath = [string]$UninstallPath
            $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -ErrorAction Stop

            Set-TemplateToken -Path (Join-Path -Path $AppFolder -ChildPath 'Intune-D-AppDetection.ps1') -Values @{
                NAME    = $Name
                VERSION = $Version.ToString()
            }

            Write-Output "The application '$Name' has been successfully packaged.`nThis can be found in the folder '$AppFolder'."

            if ($CreateIntuneWinPackage) {
                $Package = New-APFIntuneWinPackage -SourceFolder $AppFolder -SetupFile (Join-Path -Path $AppFolder -ChildPath $InstallerFile.Name) -OutputFolder $DestinationFolder -ErrorAction Stop
                if ($Package) {
                    Write-Output "The application '$Name' was also packaged to an intunewin file.`nThis can be found at '$($Package.FullName)'."
                }
            }
            $CommandLine = Get-APFCommandLine
            Write-Output "When publishing the application to Intune, use`n'$($CommandLine.InstallCommand)' for the install command and`n'$($CommandLine.UninstallCommand)' for the uninstall command."
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            Write-Error -Message "Failed to package application: $($_.Exception.Message)" -Exception $_.Exception
        }
    }
}
