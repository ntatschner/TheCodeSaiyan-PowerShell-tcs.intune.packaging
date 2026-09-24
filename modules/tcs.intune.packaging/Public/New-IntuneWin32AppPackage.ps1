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
        (LocalApplicationData\tcs.intune.packaging) is used and the tool is downloaded there when missing.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Name, FileName, SetupFile, UnencryptedContentSize and Path of the package. Name, FileName and
        UnencryptedContentSize are read with Get-IntuneWin32AppMetaData (IntuneWin32App module) when it
        is installed; otherwise Name is the setup file name and UnencryptedContentSize is $null.

    .EXAMPLE
        New-IntuneWin32AppPackage -SourceFolder "C:\Apps\MyApp" -SetupFile "setup.exe" -OutputFolder "C:\Packages"

        Creates an .intunewin package from the MyApp folder.

    .EXAMPLE
        New-IntuneWin32AppPackage -SourceFolder "C:\Apps\MyApp" -SetupFile "installer.msi" -OutputFolder "C:\Packages" -Force

        Creates an .intunewin package and overwrites any existing package in the output folder.

    .NOTES
        The IntuneWinAppUtil.exe tool is downloaded automatically when IntuneWinAppUtilPath is not specified and the tool is missing.
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
        [string]$IntuneWinAppUtilPath = (Get-IntuneWinAppUtilPath)
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
    Process {
        try {
            # Trim trailing path separators from input paths
            $SourceFolder = $SourceFolder.TrimEnd('\', '/')
            $OutputFolder = $OutputFolder.TrimEnd('\', '/')

            if ((Test-Path -Path $SourceFolder) -or (Test-Path -LiteralPath $SourceFolder)) {
                Write-Verbose -Message "Successfully detected specified source folder: $($SourceFolder)"

                $SetupFilePath = (Join-Path -Path $SourceFolder -ChildPath $SetupFile)
                if ((Test-Path -Path $SetupFilePath) -or (Test-Path -LiteralPath $SetupFilePath)) {
                    Write-Verbose -Message "Successfully detected specified setup file '$($SetupFile)' in source folder"

                    if ((Test-Path -Path $OutputFolder) -or (Test-Path -LiteralPath $OutputFolder)) {
                        Write-Verbose -Message "Successfully detected specified output folder: $($OutputFolder)"

                        if ((-not(Test-Path -Path $IntuneWinAppUtilPath)) -or (-not(Test-Path -LiteralPath $IntuneWinAppUtilPath))) {
                            if (-not($PSBoundParameters["IntuneWinAppUtilPath"])) {
                                # Download IntuneWinAppUtil.exe to the per-user tool folder
                                $ToolFolder = Split-Path -Path $IntuneWinAppUtilPath -Parent
                                Write-Verbose -Message "Unable to detect IntuneWinAppUtil.exe, attempting to download to: $ToolFolder"
                                $null = Get-IntunePackagingTool -Path $ToolFolder -Force
                            }
                        }

                        if ((Test-Path -Path $IntuneWinAppUtilPath) -or (Test-Path -LiteralPath $IntuneWinAppUtilPath)) {
                            Write-Verbose -Message "Successfully detected IntuneWinAppUtil.exe in: $($IntuneWinAppUtilPath)"

                            # If .intunewin already exists, only continue if Force parameter is passed on command line
                            $ProcessPackage = $true
                            $IntuneWinAppPackage = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFile)).intunewin"
                            if ((Test-Path -Path $IntuneWinAppPackage) -or (Test-Path -LiteralPath $IntuneWinAppPackage)) {
                                if ($Force) {
                                    Write-Verbose -Message "Package file already exist, but Force parameter was specified to overwrite existing file"
                                }
                                else {
                                    Write-Warning -Message "Package file already exist, specify the Force parameter to overwrite existing file"
                                    $ProcessPackage = $false
                                }
                            }

                            # Continue processing if allowed
                            if ($ProcessPackage -eq $true -and $PSCmdlet.ShouldProcess($IntuneWinAppPackage, 'Create .intunewin package')) {
                                # Invoke IntuneWinAppUtil.exe with parameter inputs
                                Write-Verbose -Message "Invoking IntuneWinAppUtil.exe to initialize packaging process"
                                $PackageInvocation = Invoke-Executable -FilePath $IntuneWinAppUtilPath -Arguments "-c ""$($SourceFolder)"" -s ""$($SetupFile)"" -o ""$($OutPutFolder)"" -q" -RedirectStandardOutput $false -RedirectStandardError $false -CreateNoWindow $false -UseShellExecute $true
                                if ($PackageInvocation.ExitCode -eq 0) {
                                    Write-Verbose -Message "IntuneWinAppUtil.exe packaging process completed with exit code $($PackageInvocation.ExitCode)"

                                    # Test if .intunewin file exists after packaging process completed
                                    if ((Test-Path -Path $IntuneWinAppPackage) -or (Test-Path -LiteralPath $IntuneWinAppPackage)) {
                                        Write-Verbose -Message "Successfully created Win32 app package object"

                                        # Construct output object with package details. Get-IntuneWin32AppMetaData comes from
                                        # the optional IntuneWin32App module and is used when it is installed.
                                        $PSObject = [PSCustomObject]@{
                                            "Name"                   = $SetupFile
                                            "FileName"               = Split-Path -Path $IntuneWinAppPackage -Leaf
                                            "SetupFile"              = $SetupFile
                                            "UnencryptedContentSize" = $null
                                            "Path"                   = $IntuneWinAppPackage
                                        }
                                        if (Get-Command -Name 'Get-IntuneWin32AppMetaData' -ErrorAction SilentlyContinue) {
                                            $IntuneWinAppMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinAppPackage
                                            $PSObject.Name = $IntuneWinAppMetaData.ApplicationInfo.Name
                                            $PSObject.FileName = $IntuneWinAppMetaData.ApplicationInfo.FileName
                                            $PSObject.SetupFile = $IntuneWinAppMetaData.ApplicationInfo.SetupFile
                                            $PSObject.UnencryptedContentSize = $IntuneWinAppMetaData.ApplicationInfo.UnencryptedContentSize
                                        }
                                        Write-Output -InputObject $PSObject
                                    }
                                    else {
                                        Write-Warning -Message "Unable to detect expected '$($SetupFile).intunewin' file after IntuneWinAppUtil.exe invocation"
                                    }
                                }
                                else {
                                    Write-Warning -Message "Unexpected error occurred while packaging Win32 app. Return code from invocation: $($PackageInvocation.ExitCode)"
                                }
                            }
                        }
                        else {
                            Write-Warning -Message "Unable to detect IntuneWinAppUtil.exe in: $($IntuneWinAppUtilPath)"
                        }
                    }
                    else {
                        Write-Warning -Message "Unable to detect specified output folder: $($OutputFolder)"
                    }
                }
                else {
                    Write-Warning -Message "Unable to detect specified setup file '$($SetupFile)' in source folder: $($SourceFolder)"
                }
            }
            else {
                Write-Warning -Message "Unable to detect specified source folder: $($SourceFolder)"
            }
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            throw
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
