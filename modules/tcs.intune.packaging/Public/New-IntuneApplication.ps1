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
        Array of paths to the source files that will be included in the application package.

    .PARAMETER MainInstallerFileName
        The filename of the main installer executable or MSI file.

    .PARAMETER OutputFolder
        The folder where the application package will be created. Default is the current directory.

    .PARAMETER Description
        A description of the application. Default includes ApplicationName, Publisher, Version, Developer, and notes.

    .PARAMETER Publisher
        The publisher of the application. Default is the current username.

    .PARAMETER Version
        The version of the application. Default is "1.0".

    .PARAMETER Developer
        The developer of the application. Default is the current username.

    .PARAMETER owner
        The owner of the application.

    .PARAMETER notes
        Additional notes about the application.

    .PARAMETER LogoPath
        Path to the application logo image file. Must be a PNG, JPG, or JPEG file.

    .PARAMETER InstallFor
        Specifies the installation context: "User" or "System". Default is "System".

    .EXAMPLE
        New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\*" -MainInstallerFileName "setup.exe"
        
        Creates an Intune application package for MyApp in the current directory.

    .EXAMPLE
        New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\installer.msi", "C:\Source\config.xml" -MainInstallerFileName "installer.msi" -OutputFolder "C:\Packages" -Version "2.1" -LogoPath "C:\Images\logo.png"
        
        Creates an Intune application package with specific version and logo.

    .OUTPUTS
        PSObject containing information about the created application package.
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
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

        [ValidateNotNullOrEmpty()]
        [string]$Description = "# $ApplicationName`nPublisher: $Publisher`nVersion: $Version`nDeveloper: $Developer`n`n$notes",

        [ValidateNotNullOrEmpty()]
        [string]$Publisher = $Env:USERNAME,

        [string]$Version = "1.0",

        [string]$Developer = $Env:USERNAME,

        [string]$owner = "",

        [string]$notes = "",

        [ValidateScript({
                if (Test-Path -Path $_) {
                    if ($(Get-Item -Path $_).Extension -notin @('.png', '.jpg', '.jpeg')) {
                        throw "The LogoPath must be a PNG or JPG file."
                    }
                    else {
                        $true
                    }
                }
                else {
                    throw "The LogoPath path does not exist."
                }
                $true
            })]
        [string]$LogoPath,
        
        [ValidateSet("User", "System")]
        [string]$InstallFor = "System",

        [ValidateSet("basedOnReturnCode", "allow", "suppress", "force")]
        [string]$RestartBehavior = "basedOnReturnCode",

        [bool]$isFeatured = $false,

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
        [string]$IntuneToolsPath = ".\IntuneWinAppUtil.exe",

        [switch]$Overwrite,

        [switch]$NoJson,

        [switch]$NoIntuneWin,

        [switch]$NoCleanUp
    )
    
    begin {
        #region PathValidation
        # Start by validating any paths passed to the function
        # Requirements Rule Script
        if ($RequirementRuleType -eq 'Script') {
            if (-not (Test-Path -Path $RequirementRuleScript)) {
                Write-Error "The RequirementRuleScript path '$RequirementRuleScript' does not exist."
                return
            }
        }
        # Detection Rule Script
        if ($DetectionRuleType -eq 'Script') {
            if (-not (Test-Path -Path $DetectionRuleScript)) {
                Write-Error "The DetectionRuleScript path '$DetectionRuleScript' does not exist."
                return
            }
        }
        # Image Path
        if ($LogoPath) {
            try {
                Test-IntuneLogoImage -Path $LogoPath -ErrorAction Stop
            }
            catch {
                Write-Error $_.Exception.Message
                return
            }
        }
        foreach ($File in $SourceFiles) {
            if (-not (Test-Path -Path $File)) {
                Write-Error "The Source File path '$File' does not exist."
                return
            }
        }
        if (-not (Test-Path -Path $OutputFolder)) {
            Write-Error "The Output Folder path '$OutputFolder' does not exist."
            return
        }
        #endregion PathValidation
        #region SourceFilesValidation
        # Validate the MainInstallerFileName is in the list of SourceFiles
        if ($SourceFiles.count -eq 1 -and (Test-Path -Path $SourceFiles[0] -PathType Container) -eq $false ) {
            if (Test-Path -Path $MainInstallerFileName -PathType Leaf) {
                $local:MainInstallerFilePath = Split-Path -Path $MainInstallerFileName -Parent
                $local:MainInstallerFileName = Split-Path -Path $MainInstallerFileName -Leaf
            }
            if ($(Split-Path -Path $SourceFiles[0] -Leaf) -ne $MainInstallerFileName) {
                Write-Error "The MainInstallerFileName '$MainInstallerFileName' does not exist in the SourceFiles list."
                return
            }
        }
        elseif ($SourceFiles.count -eq 1) {
            $MainInstallerFileNameFound = $false
            foreach ($File in $(Get-ChildItem -Path $SourceFiles[0] -Recurse -File | Select-Object -ExpandProperty FullName)) {
                if ($(Split-Path -Path $File -Leaf) -eq $MainInstallerFileName) {
                    $MainInstallerFileNameFound = $true
                    $local:MainInstallerFilePath = Split-Path -Path $File -Parent
                    break
                }
            }
        }

        foreach ($File in $SourceFiles) {
            if ($(Split-Path -Path $File -Leaf) -eq $MainInstallerFileName) {
                $MainInstallerFileNameFound = $true
                $local:MainInstallerFilePath = Split-Path -Path $File -Parent
                break
            }
        }
        if ($MainInstallerFileNameFound -eq $false) {
            Write-Error "The MainInstallerFileName '$MainInstallerFileName' does not exist in the SourceFiles list."
            break
        }
        #endregion SourceFilesValidation
        #region IntuneWinAppUtilValidation
        # Now test if the IntuneWinAppUtil.exe tool is available
        if ((Test-Path -Path $IntuneToolsPath) -eq $false) {
            # If not found, download the tool from the internet
            # Amend this to pull latest version from GitHub - remove -DownloadTag
            try {
                # Pinning to v1.8.6 as a know stable release
                Get-IntunePackagingTool -Path ".\" -Force -DownloadTag "v1.8.6" -ErrorAction Stop
            }
            catch {
                Write-Error $_.Exception.Message
                return
            }
        }
        #endregion IntuneWinAppUtilValidation
        #region ParameterSplat
        # Using the parameters passed to the function, create a splat.
        $ParameterSplat = @{}
        foreach ($P in $PSBoundParameters.Keys) {
            $ParameterSplat.Add($P, $PSBoundParameters[$P])
        }
        # Removing Verbose, Debug, and ErrorAction parameters
        $ParameterSplat.Remove('Verbose')
        $ParameterSplat.Remove('Debug')
        $ParameterSplat.Remove('ErrorAction')
        # Manually adding the paremeters that have default values
        $ParameterSplat.Add('Publisher', $Publisher)
        $ParameterSplat.Add('Version', $Version)
        $ParameterSplat.Add('Developer', $Developer)
        $ParameterSplat.Add('InstallFor', $InstallFor)
        $ParameterSplat.Add('RestartBehavior', $RestartBehavior)
        $ParameterSplat.Add('isFeatured', $isFeatured)
        $ParameterSplat.Add('OutputFolder', $OutputFolder)
        $ParamVerbose = "$($($ParameterSplat.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "`n")"
        Write-Verbose "`n$ParamVerbose"
        #endregion ParameterSplat
    }
    process {
        #region CreateJSON
        # Create JSON file
        if ($NoJson -eq $false) {
            Write-Verbose "Creating JSON file for $ApplicationName"
            $JSONOutputPath = "$OutputFolder\$ApplicationName.$Version.json"
            if ($Overwrite -eq $true -and (Test-Path -Path $JSONOutputPath) -eq $true) {
                Write-Verbose "Overwriting existing JSON file"
                Remove-Item -Path $JSONOutputPath -Force -Confirm:$false
            }
            elseif ((Test-Path -Path $JSONOutputPath) -eq $true) {
                Write-Error "The JSON file already exists, use -Overwrite to replace it."
                break
            }
            $JSON = New-IntuneAppJSON -AppParams $ParameterSplat
            $JSON | Out-File -FilePath $JSONOutputPath -Force -Confirm:$false
        }
        #endregion CreateJSON
        #region CreateIntuneWin
        # Create .intunewin file
        if ($NoIntuneWin -eq $false) {
            Write-Verbose "Creating .intunewin file for $ApplicationName"
            # If source files are multiple files, create a temp folder and copy the files to it
            if ($SourceFiles.count -gt 1) {
                # Create a Temp folder to store SourceFiles
                $TempFolder = New-Item -Path "$OutputFolder\$ApplicationName.$Version" -ItemType Directory -Force
                Copy-item -Path $SourceFiles -Destination $TempFolder.FullName -Force -Confirm:$false
                $SourceFiles = $TempFolder.FullName
            }
            else {
                if ((Test-Path -Path $SourceFiles[0] -PathType Container) -eq $false) {
                    $SourceFiles = Split-Path -Path $SourceFiles[0] -Parent
                }
            }
            $IntunewinFullPath = Join-Path -Path $OutputFolder -ChildPath "$((Get-Item -Path "$MainInstallerFilePath\$MainInstallerFileName" -ErrorAction SilentlyContinue).BaseName).intunewin"
            $ExistingIntunewinTest = Test-Path -Path $IntunewinFullPath
            $MainInstallerFileFullPath = "$MainInstallerFilePath\$MainInstallerFileName"
            $CreateIntuneWin = $true
            if ($Overwrite -eq $true -and $ExistingIntunewinTest -eq $true) {
                Write-Verbose "Overwriting existing .intunewin file"
                Remove-Item -Path $IntunewinFullPath -Force -Confirm:$false
            }
            elseif ($ExistingIntunewinTest -eq $true) {
                Write-Error "The .intunewin file already exists, use -Overwrite to replace it."
                $CreateIntuneWin = $false
                return       
            }
            if ($CreateIntuneWin -eq $true) {
                try {
                    Start-Process -FilePath $IntuneToolsPath -ArgumentList "-c $SourceFiles -o $OutputFolder -s $MainInstallerFileFullPath -q" -Wait -WindowStyle Hidden -ErrorAction Stop | Out-Null
                }
                catch {
                    Write-Error $_.Exception.Message
                    return
                }
            }
        }
        #endregion CreateIntuneWin
        #region PublishIntune
        # Publish to Intune
        if ($Publish -eq $true) {
            Write-Verbose "Publishing $ApplicationName to Intune"
            try {
                
            }
            catch {
                Write-Error $_.Exception.Message
                return
            }
        }
    }
    end {
        # Cleanup
        if ($NoCleanUp -eq $false -and $Publish -eq $true) {
            Write-Verbose "Cleaning up temporary files"
            if ($SourceFiles.count -gt 1) {
                Remove-Item -Path $TempFolder.FullName -Recurse -Force -Confirm:$false
            }
            if ($NoJson -eq $false) {
                Remove-Item -Path "$OutputFolder\$ApplicationName.$Version.json" -Force -Confirm:$false
            }
            if ($NoIntuneWin -eq $false) {
                Remove-Item -Path $IntunewinFullPath -Force -Confirm:$false
            }
        }
    }
}
