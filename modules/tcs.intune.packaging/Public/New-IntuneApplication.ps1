function New-IntuneApplication {
    <#
    .SYNOPSIS
        Creates a new Intune application package with all necessary files and configurations.

    .DESCRIPTION
        The New-IntuneApplication function creates a complete Intune application package by generating
        the required folder structure, copying source files, creating detection scripts, and preparing
        all necessary configuration files for deployment.

    .PARAMETER ApplicationName
        The name of the application to be packaged.

    .PARAMETER SourceFiles
        The source files for the package: either one folder that contains all files, or one or more files
        and folders. When several are given they are copied (folders with their contents) to a temporary
        staging folder, which is removed after the .intunewin package is created.

    .PARAMETER MainInstallerFileName
        The file name of the main installer (for example setup.exe or installer.msi). It must be one of
        the source files, or be inside the source folder.

    .PARAMETER OutputFolder
        The existing folder where the JSON and .intunewin files are created. Default is the current directory.

    .PARAMETER Description
        A description of the application. Default is a Markdown summary of ApplicationName, Publisher,
        Version, Developer and Notes.

    .PARAMETER Publisher
        The publisher of the application. Default is the current user name.

    .PARAMETER Version
        The version of the application. Default is "1.0".

    .PARAMETER Developer
        The developer of the application. Default is the current user name.

    .PARAMETER Owner
        The owner of the application.

    .PARAMETER Notes
        Additional notes about the application.

    .PARAMETER LogoPath
        Path to the application logo: a PNG or JPG image of at most 256x256 pixels.

    .PARAMETER InstallFor
        The installation context: "User" or "System". Default is "System".

    .PARAMETER RestartBehavior
        The device restart behaviour: basedOnReturnCode (default), allow, suppress or force.

    .PARAMETER IsFeatured
        Whether the application is featured in the Company Portal. Default is $false.

    .PARAMETER InstallCommand
        The command line that installs the application.

    .PARAMETER UninstallCommand
        The command line that uninstalls the application.

    .PARAMETER RequirementRuleConfig
        A hashtable that describes the requirement rules; written to the JSON file.

    .PARAMETER DetectionRuleConfig
        A hashtable that describes the detection rules (for example from New-IntuneWin32Rule); written to the JSON file.

    .PARAMETER AssignmentType
        How the application is assigned: User-Group, Device-Group, All-Users or All-Devices. Written to
        the JSON file; Publish-IntuneAppPackage (and -Publish) assigns the app with it.

    .PARAMETER AssignmentGroup
        The group (ID or display name) the application is assigned to, for the User-Group and
        Device-Group assignment types.

    .PARAMETER AssignmentIntent
        The assignment intent: required (default), available or uninstall.

    .PARAMETER FilterRuleType
        Whether the assignment filter includes or excludes devices: Include or Exclude. Use with FilterRule.

    .PARAMETER FilterRule
        The name or ID of an existing Intune assignment filter. Use with FilterRuleType.

    .PARAMETER Publish
        Publishes the package to Intune with Publish-IntuneAppPackage after creating it and assigns it
        as set by AssignmentType, AssignmentGroup, AssignmentIntent and the filter parameters.
        DetectionRuleConfig (and RequirementRuleConfig) must then be rules created with
        New-IntuneWin32Rule. With -Overwrite an existing app with the same name gets the package as a
        new content version and its properties are updated. The assignment settings are checked before
        anything is built.

    .PARAMETER IntuneToolsPath
        The path to IntuneWinAppUtil.exe. When the file does not exist, the tool in the per-user tool
        folder (LocalApplicationData\tcs.intune.packaging) is used; when it is missing there too you are
        asked before release v1.8.6 is downloaded (see AllowDownload).

    .PARAMETER AllowDownload
        Download IntuneWinAppUtil.exe to the per-user tool folder without asking when it is missing.
        The download is refused unless it is signed by Microsoft (see Get-IntunePackagingTool).

    .PARAMETER Overwrite
        Overwrite existing JSON and .intunewin files in OutputFolder.

    .PARAMETER NoJson
        Do not create the JSON configuration file.

    .PARAMETER NoIntuneWin
        Do not create the .intunewin package.

    .PARAMETER NoCleanUp
        Keep the JSON file and .intunewin package after a successful -Publish (they are removed by default).

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        JsonPath and IntuneWinPath of the created files ($null for files that were not created or were
        removed after publishing) and App, the published app when -Publish is used.

    .EXAMPLE
        New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\MyApp" -MainInstallerFileName "setup.exe" -InstallCommand "setup.exe /S" -UninstallCommand "setup.exe /U" -DetectionRuleConfig @{ Type = 'File'; Path = 'C:\Program Files\MyApp' } -AssignmentType All-Devices

        Creates MyApp.1.0.json and setup.intunewin in the current directory.

    .EXAMPLE
        New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\installer.msi", "C:\Source\config.xml" -MainInstallerFileName "installer.msi" -OutputFolder "C:\Packages" -Version "2.1" -InstallCommand "msiexec /i installer.msi /qn" -UninstallCommand "msiexec /x installer.msi /qn" -DetectionRuleConfig @{ Type = 'MSI' } -AssignmentType User-Group -AssignmentGroup 'Intune-AG-MyApp-Available' -NoIntuneWin

        Creates only the JSON configuration file for version 2.1.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$SourceFiles,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MainInstallerFileName,

        [string]$OutputFolder = $($PWD.Path),

        [string]$Description,

        [ValidateNotNullOrEmpty()]
        [string]$Publisher = [Environment]::UserName,

        [string]$Version = "1.0",

        [string]$Developer = [Environment]::UserName,

        [string]$Owner = "",

        [string]$Notes = "",

        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    throw "The LogoPath path does not exist."
                }
                if ([System.IO.Path]::GetExtension($_) -notin @('.png', '.jpg', '.jpeg')) {
                    throw "The LogoPath must be a PNG or JPG file."
                }
                $true
            })]
        [string]$LogoPath,

        [ValidateSet("User", "System")]
        [string]$InstallFor = "System",

        [ValidateSet("basedOnReturnCode", "allow", "suppress", "force")]
        [string]$RestartBehavior = "basedOnReturnCode",

        [bool]$IsFeatured = $false,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommand,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommand,

        [hashtable]$RequirementRuleConfig,

        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionRuleConfig,

        [Parameter(Mandatory = $true)]
        [ValidateSet('User-Group', 'Device-Group', 'All-Users', 'All-Devices')]
        [string]$AssignmentType,

        [string]$AssignmentGroup,

        [ValidateSet('required', 'available', 'uninstall')]
        [string]$AssignmentIntent = 'required',

        [ValidateSet('Include', 'Exclude')]
        [string]$FilterRuleType,

        [string]$FilterRule,

        [switch]$Publish,

        [ValidateNotNullOrEmpty()]
        [string]$IntuneToolsPath = (Get-IntuneWinAppUtilPath),

        [switch]$AllowDownload,

        [switch]$Overwrite,

        [switch]$NoJson,

        [switch]$NoIntuneWin,

        [switch]$NoCleanUp
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
        try {
            # Checked before anything is built: publishing needs both files
            if ($Publish -and ($NoJson -or $NoIntuneWin)) {
                throw 'Publish needs both the JSON file and the .intunewin package; do not combine it with -NoJson or -NoIntuneWin.'
            }
            if ($Publish) {
                Test-IntuneAppAssignmentSetting -AssignmentType $AssignmentType -AssignmentGroup $AssignmentGroup -Intent $AssignmentIntent -FilterRuleType $FilterRuleType -FilterRule $FilterRule
            }
            # The JSON file is named "<ApplicationName>.<Version>.json" in OutputFolder
            Assert-SafePathSegment -Name "$ApplicationName.$Version" -ParameterName 'ApplicationName and Version' -AllowWildcard

            #region PathValidation
            if ($LogoPath) {
                if (-not (Test-IntuneLogoImage -Path $LogoPath -ErrorAction Stop)) {
                    throw "The logo '$LogoPath' is not a valid Intune logo image."
                }
            }
            foreach ($File in $SourceFiles) {
                if (-not (Test-Path -Path $File)) {
                    throw "The Source File path '$File' does not exist."
                }
            }
            if (-not (Test-Path -Path $OutputFolder -PathType Container)) {
                throw "The Output Folder path '$OutputFolder' does not exist."
            }
            #endregion PathValidation

            #region SourceFilesValidation
            # Find the main installer in the source files (or in the single source folder)
            if (Test-Path -Path $MainInstallerFileName -PathType Leaf) {
                $MainInstallerFileName = Split-Path -Path $MainInstallerFileName -Leaf
            }
            $MainInstallerFilePath = $null
            if ($SourceFiles.Count -eq 1 -and (Test-Path -Path $SourceFiles[0] -PathType Container)) {
                $Found = Get-ChildItem -Path $SourceFiles[0] -Recurse -File | Where-Object { $_.Name -eq $MainInstallerFileName } | Select-Object -First 1
                if ($Found) {
                    $MainInstallerFilePath = $Found.DirectoryName
                }
            }
            else {
                foreach ($File in $SourceFiles) {
                    if ((Split-Path -Path $File -Leaf) -eq $MainInstallerFileName) {
                        $MainInstallerFilePath = Split-Path -Path (Resolve-Path -Path $File).ProviderPath -Parent
                        break
                    }
                }
            }
            if (-not $MainInstallerFilePath) {
                throw "The MainInstallerFileName '$MainInstallerFileName' does not exist in the SourceFiles list."
            }
            #endregion SourceFilesValidation

            if (-not $PSBoundParameters.ContainsKey('Description')) {
                $Description = "# $ApplicationName`nPublisher: $Publisher`nVersion: $Version`nDeveloper: $Developer`n`n$Notes"
            }

            #region ParameterSplat
            # Using the parameters passed to the function (and the defaults), create a splat for the JSON file
            $CommonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
            $ParameterSplat = @{}
            foreach ($P in $PSBoundParameters.Keys) {
                if ($P -notin $CommonParameters) {
                    $ParameterSplat[$P] = $PSBoundParameters[$P]
                }
            }
            $ParameterSplat['MainInstallerFileName'] = $MainInstallerFileName
            $ParameterSplat['Description'] = $Description
            $ParameterSplat['Publisher'] = $Publisher
            $ParameterSplat['Version'] = $Version
            $ParameterSplat['Developer'] = $Developer
            $ParameterSplat['InstallFor'] = $InstallFor
            $ParameterSplat['RestartBehavior'] = $RestartBehavior
            $ParameterSplat['IsFeatured'] = $IsFeatured
            $ParameterSplat['OutputFolder'] = $OutputFolder
            $ParameterSplat['AssignmentIntent'] = $AssignmentIntent
            # Command options, not application settings
            foreach ($Option in 'Publish', 'IntuneToolsPath', 'AllowDownload', 'Overwrite', 'NoJson', 'NoIntuneWin', 'NoCleanUp') {
                $ParameterSplat.Remove($Option)
            }
            Write-Verbose ("`n" + (($ParameterSplat.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "`n"))
            #endregion ParameterSplat
        }
        catch {
            $TelemetryFailed = $true
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
    process {
        try {
            $JSONOutputPath = $null
            $IntunewinFullPath = $null
            $StagingFolder = $null

            #region CreateJSON
            if (-not $NoJson) {
                Write-Verbose "Creating JSON file for $ApplicationName"
                $JSONOutputPath = Join-Path -Path $OutputFolder -ChildPath "$ApplicationName.$Version.json"
                if ((Test-Path -LiteralPath $JSONOutputPath) -and -not $Overwrite) {
                    throw "The JSON file '$JSONOutputPath' already exists, use -Overwrite to replace it."
                }
                if ($PSCmdlet.ShouldProcess($JSONOutputPath, 'Write application JSON')) {
                    New-IntuneAppJSON -AppParams $ParameterSplat | Set-Content -LiteralPath $JSONOutputPath -Force -ErrorAction Stop
                }
            }
            #endregion CreateJSON

            #region CreateIntuneWin
            if (-not $NoIntuneWin) {
                Write-Verbose "Creating .intunewin file for $ApplicationName"
                $MainInstallerFileFullPath = Join-Path -Path $MainInstallerFilePath -ChildPath $MainInstallerFileName
                $IntunewinFullPath = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($MainInstallerFileName)).intunewin"
                if ((Test-Path -LiteralPath $IntunewinFullPath) -and -not $Overwrite) {
                    throw "The .intunewin file '$IntunewinFullPath' already exists, use -Overwrite to replace it."
                }
                if ($PSCmdlet.ShouldProcess($IntunewinFullPath, 'Create .intunewin package')) {
                    try {
                        # IntuneWinAppUtil.exe needs one source folder: copy multiple source files (and folders,
                        # with their contents) to a temporary staging folder outside OutputFolder
                        if ($SourceFiles.Count -gt 1) {
                            $StagingFolder = New-Item -Path (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "tcs-intune-staging-$([guid]::NewGuid().ToString('N'))") -ItemType Directory -Force -ErrorAction Stop
                            Copy-Item -Path $SourceFiles -Destination $StagingFolder.FullName -Recurse -Force -ErrorAction Stop
                            $SourceFolder = $StagingFolder.FullName
                            $MainInstallerFileFullPath = Join-Path -Path $SourceFolder -ChildPath $MainInstallerFileName
                        }
                        elseif (Test-Path -Path $SourceFiles[0] -PathType Container) {
                            $SourceFolder = (Resolve-Path -Path $SourceFiles[0]).ProviderPath
                        }
                        else {
                            $SourceFolder = $MainInstallerFilePath
                        }

                        $ToolParameters = @{
                            SourceFolder  = $SourceFolder
                            SetupFile     = $MainInstallerFileFullPath
                            OutputFolder  = $OutputFolder
                            AllowDownload = $AllowDownload
                            Overwrite     = $true
                        }
                        # A missing IntuneToolsPath falls back to the per-user tool folder (and its download policy)
                        if (Test-Path -LiteralPath $IntuneToolsPath -PathType Leaf) {
                            $ToolParameters['ToolPath'] = $IntuneToolsPath
                        }
                        $IntunewinFullPath = (Invoke-IntuneWinAppUtil @ToolParameters -ErrorAction Stop).FullName
                    }
                    finally {
                        # The staging copy is only needed while the package is built
                        if ($StagingFolder) {
                            Remove-Item -LiteralPath $StagingFolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
            #endregion CreateIntuneWin

            $App = $null
            if ($Publish) {
                if ($PSCmdlet.ShouldProcess($ApplicationName, 'Publish to Intune')) {
                    $App = Publish-IntuneAppPackage -IntuneAppJSONPath $JSONOutputPath -IntuneWinPath $IntunewinFullPath -Force:$Overwrite -ErrorAction Stop
                    if (-not $NoCleanUp) {
                        Write-Verbose 'Removing the published JSON file and .intunewin package.'
                        Remove-Item -LiteralPath $JSONOutputPath, $IntunewinFullPath -Force -ErrorAction SilentlyContinue
                        $JSONOutputPath = $null
                        $IntunewinFullPath = $null
                    }
                }
            }

            [PSCustomObject]@{
                JsonPath      = $JSONOutputPath
                IntuneWinPath = $IntunewinFullPath
                App           = $App
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
