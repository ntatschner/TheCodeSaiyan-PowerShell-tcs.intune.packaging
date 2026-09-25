function New-IntuneWin32AppPackage {
    <#
    .SYNOPSIS
        Creates an Intune Win32 application package (.intunewin file) from source files.

    .DESCRIPTION
        The New-IntuneWin32AppPackage function wraps application source files and the main setup file
        into an encrypted .intunewin package using Microsoft's IntuneWinAppUtil.exe tool. This package
        can then be uploaded to Microsoft Intune for Win32 app deployment.

    .PARAMETER SourceFolder
        The full path to the source folder containing the setup file and all dependency files.

    .PARAMETER SetupFile
        The complete setup file name including extension (e.g., Setup.exe or Installer.msi).

    .PARAMETER OutputFolder
        The full path to the output folder where the packaged .intunewin file will be saved.

    .PARAMETER Force
        Switch to overwrite an existing .intunewin file if already present in the output folder.

    .PARAMETER IntuneWinAppUtilPath
        The full path to the IntuneWinAppUtil.exe file. When not specified, the per-user tool folder
        (LocalApplicationData\tcs.intune.packaging) is used. When the tool is missing there you are asked
        before release v1.8.6 is downloaded (see AllowDownload).

    .PARAMETER AllowDownload
        Download IntuneWinAppUtil.exe to the per-user tool folder without asking when it is missing.
        The download is refused unless it is signed by Microsoft (see Get-IntunePackagingTool).

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Name, FileName, SetupFile and UnencryptedContentSize from the package metadata (Detection.xml),
        and Path of the .intunewin file.

    .EXAMPLE
        New-IntuneWin32AppPackage -SourceFolder "C:\Apps\MyApp" -SetupFile "setup.exe" -OutputFolder "C:\Packages"

        Creates an .intunewin package from the MyApp folder.

    .EXAMPLE
        New-IntuneWin32AppPackage -SourceFolder "C:\Apps\MyApp" -SetupFile "installer.msi" -OutputFolder "C:\Packages" -Force

        Creates an .intunewin package and overwrites any existing package in the output folder.

    .NOTES
        A missing source folder, setup file, output folder or tool, or a failure of IntuneWinAppUtil.exe,
        is a terminating error. An existing package without -Force is a non-terminating error and the
        package is not created. Both are reported to telemetry as failures.
        The source folder should contain all files required for the application installation.

    .LINK
        https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the source folder where the setup file and all of it's potential dependency files reside.")]
        [ValidateNotNullOrEmpty()]
        [string]$SourceFolder,

        [parameter(Mandatory = $true, HelpMessage = "Specify the complete setup file name including it's file extension, e.g. Setup.exe or Installer.msi.")]
        [ValidateNotNullOrEmpty()]
        [string]$SetupFile,

        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the output folder where the packaged .intunewin file will be exported to.")]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFolder,

        [parameter(Mandatory = $false, HelpMessage = "Specify to overwrite existing packaged .intunewin file if already present in output folder.")]
        [switch]$Force,

        [parameter(Mandatory = $false, HelpMessage = "Specify the full path to the IntuneWinAppUtil.exe file.")]
        [ValidateNotNullOrEmpty()]
        [string]$IntuneWinAppUtilPath = (Get-IntuneWinAppUtilPath),

        [parameter(Mandatory = $false, HelpMessage = "Download IntuneWinAppUtil.exe without asking when it is missing.")]
        [switch]$AllowDownload
    )
    begin {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        $TelemetryFailed = $false
    }
    process {
        try {
            if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
                throw "Unable to detect specified source folder: $SourceFolder"
            }
            $SetupFilePath = Join-Path -Path $SourceFolder -ChildPath $SetupFile
            if (-not (Test-Path -LiteralPath $SetupFilePath -PathType Leaf)) {
                throw "Unable to detect specified setup file '$SetupFile' in source folder: $SourceFolder"
            }
            if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
                throw "Unable to detect specified output folder: $OutputFolder"
            }

            $IntuneWinAppPackage = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFile)).intunewin"
            if ((Test-Path -LiteralPath $IntuneWinAppPackage) -and -not $Force) {
                # The package is skipped, but other pipeline input is still processed
                $Exception = [System.IO.IOException]::new("The package '$IntuneWinAppPackage' already exists. Use -Force to overwrite it.")
                $Record = [System.Management.Automation.ErrorRecord]::new($Exception, 'PackageExists', [System.Management.Automation.ErrorCategory]::ResourceExists, $IntuneWinAppPackage)
                if (-not $TelemetryFailed) {
                    $TelemetryFailed = $true
                    Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $Record
                }
                $PSCmdlet.WriteError($Record)
                return
            }
            if (-not $PSCmdlet.ShouldProcess($IntuneWinAppPackage, 'Create .intunewin package')) {
                return
            }

            $ToolParameters = @{
                SourceFolder  = $SourceFolder
                SetupFile     = $SetupFilePath
                OutputFolder  = $OutputFolder
                AllowDownload = $AllowDownload
                Overwrite     = $Force
            }
            if ($PSBoundParameters.ContainsKey('IntuneWinAppUtilPath')) {
                $ToolParameters['ToolPath'] = $IntuneWinAppUtilPath
            }
            $Package = Invoke-IntuneWinAppUtil @ToolParameters -ErrorAction Stop
            $Info = Read-IntuneWinPackage -Path $Package.FullName -ErrorAction Stop
            [PSCustomObject]@{
                Name                   = $Info.Name
                FileName               = $Info.FileName
                SetupFile              = $Info.SetupFile
                UnencryptedContentSize = $Info.UnencryptedContentSize
                Path                   = $Package.FullName
            }
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
