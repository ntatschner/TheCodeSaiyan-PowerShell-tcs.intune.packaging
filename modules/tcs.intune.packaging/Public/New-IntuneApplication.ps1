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
        The source files for the package: either one folder that contains all files, or one or more files.
        When several files are given they are copied to "<OutputFolder>/<ApplicationName>.<Version>" first.

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
        How the application is assigned: User-Group, Device-Group, All-Users or All-Devices.

    .PARAMETER AssignmentGroup
        The group the application is assigned to, for the User-Group and Device-Group assignment types.

    .PARAMETER FilterRuleType
        Whether the assignment filter includes or excludes devices: Include or Exclude.

    .PARAMETER FilterRule
        The assignment filter rule.

    .PARAMETER Publish
        Publishes the package to Intune with Publish-IntuneAppPackage after creating it. DetectionRuleConfig
        (and RequirementRuleConfig) must then be rules created with New-IntuneWin32Rule. With -Overwrite an
        existing app with the same name gets the package as a new content version.

    .PARAMETER IntuneToolsPath
        The path to IntuneWinAppUtil.exe. When the file does not exist, release v1.8.6 of the tool is
        downloaded to the per-user tool folder (LocalApplicationData\tcs.intune.packaging) and used.

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

        [ValidateSet('Include', 'Exclude')]
        [string]$FilterRuleType,

        [string]$FilterRule,

        [switch]$Publish,

        [ValidateNotNullOrEmpty()]
        [string]$IntuneToolsPath = (Get-IntuneWinAppUtilPath),

        [switch]$Overwrite,

        [switch]$NoJson,

        [switch]$NoIntuneWin,

        [switch]$NoCleanUp
    )

    begin {
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
        Write-Verbose ("`n" + (($ParameterSplat.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "`n"))
        #endregion ParameterSplat
    }
    process {
        $JSONOutputPath = $null
        $IntunewinFullPath = $null
        $StagingFolder = $null

        #region CreateJSON
        if (-not $NoJson) {
            Write-Verbose "Creating JSON file for $ApplicationName"
            $JSONOutputPath = Join-Path -Path $OutputFolder -ChildPath "$ApplicationName.$Version.json"
            if ((Test-Path -Path $JSONOutputPath) -and -not $Overwrite) {
                throw "The JSON file '$JSONOutputPath' already exists, use -Overwrite to replace it."
            }
            if ($PSCmdlet.ShouldProcess($JSONOutputPath, 'Write application JSON')) {
                New-IntuneAppJSON -AppParams $ParameterSplat | Set-Content -Path $JSONOutputPath -Force -ErrorAction Stop
            }
        }
        #endregion CreateJSON

        #region CreateIntuneWin
        if (-not $NoIntuneWin) {
            Write-Verbose "Creating .intunewin file for $ApplicationName"
            $MainInstallerFileFullPath = Join-Path -Path $MainInstallerFilePath -ChildPath $MainInstallerFileName
            $IntunewinFullPath = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($MainInstallerFileName)).intunewin"
            if ((Test-Path -Path $IntunewinFullPath) -and -not $Overwrite) {
                throw "The .intunewin file '$IntunewinFullPath' already exists, use -Overwrite to replace it."
            }
            if ($PSCmdlet.ShouldProcess($IntunewinFullPath, 'Create .intunewin package')) {
                # IntuneWinAppUtil.exe needs one source folder: copy multiple source files to a staging folder
                if ($SourceFiles.Count -gt 1) {
                    $StagingFolder = New-Item -Path (Join-Path -Path $OutputFolder -ChildPath "$ApplicationName.$Version") -ItemType Directory -Force -ErrorAction Stop
                    Copy-Item -Path $SourceFiles -Destination $StagingFolder.FullName -Force -ErrorAction Stop
                    $SourceFolder = $StagingFolder.FullName
                    $MainInstallerFileFullPath = Join-Path -Path $SourceFolder -ChildPath $MainInstallerFileName
                }
                elseif (Test-Path -Path $SourceFiles[0] -PathType Container) {
                    $SourceFolder = (Resolve-Path -Path $SourceFiles[0]).ProviderPath
                }
                else {
                    $SourceFolder = $MainInstallerFilePath
                }

                if (-not (Test-Path -Path $IntuneToolsPath -PathType Leaf)) {
                    # Pinned to v1.8.6 as a known stable release
                    $IntuneToolsPath = (Get-IntunePackagingTool -Path (Split-Path -Path (Get-IntuneWinAppUtilPath) -Parent) -Force -DownloadTag 'v1.8.6' -ErrorAction Stop).FullName
                }
                if (Test-Path -Path $IntunewinFullPath) {
                    Remove-Item -Path $IntunewinFullPath -Force -ErrorAction Stop
                }
                $Result = Invoke-Executable -FilePath $IntuneToolsPath -Arguments "-c `"$SourceFolder`" -s `"$MainInstallerFileFullPath`" -o `"$OutputFolder`" -q"
                if ($Result.ExitCode -ne 0 -or -not (Test-Path -Path $IntunewinFullPath)) {
                    throw "IntuneWinAppUtil.exe did not create '$IntunewinFullPath' (exit code $($Result.ExitCode)). $($Result.StandardError)"
                }
            }
        }
        #endregion CreateIntuneWin

        $App = $null
        if ($Publish) {
            if ($NoJson -or $NoIntuneWin) {
                throw 'Publish needs both the JSON file and the .intunewin package; do not combine it with -NoJson or -NoIntuneWin.'
            }
            if ($PSCmdlet.ShouldProcess($ApplicationName, 'Publish to Intune')) {
                $App = Publish-IntuneAppPackage -IntuneAppJSONPath $JSONOutputPath -IntuneWinPath $IntunewinFullPath -Force:$Overwrite -ErrorAction Stop
                if (-not $NoCleanUp) {
                    Write-Verbose 'Removing the published JSON file and .intunewin package.'
                    Remove-Item -Path $JSONOutputPath, $IntunewinFullPath -Force -ErrorAction SilentlyContinue
                    if ($StagingFolder) {
                        Remove-Item -Path $StagingFolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    }
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
}
