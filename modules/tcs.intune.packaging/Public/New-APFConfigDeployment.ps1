<#
.SYNOPSIS
Creates an APF (Application Packaging Framework) configuration deployment package for Intune.

.DESCRIPTION
This function creates a deployment package that can be used with the Application Packaging Framework (APF) to deploy applications to Intune-managed devices. The function supports various configuration types, including registry settings, PowerShell profiles, file deployments, scripts (OS, Application, User context), Windows features, standalone executables, standalone applications and custom configurations. It leverages Dynamic Parameters to expose relevant options based on the selected ConfigurationType.

.PARAMETER ConfigurationType
Specifies the type of configuration to create. Valid values are:
    - Registry: Creates a package to deploy registry settings. Use -RegistryValue to define the registry changes.
    - PowerShellProfiles: Creates a package to deploy PowerShell profiles.
    - Files: Creates a package to deploy files. Use -Files to specify the files and -FilesDirectoryName for the destination directory.
    - Script-OS: Creates a script based package to run a OS based configurations.
    - Script-App: Creates a script based package to run a App deployments.
    - Script-User: Creates a script based package to run a User Context based configurations.
    - StandAlone-Exe: Creates a package to deploy a standalone executable. Use -Path to specify the executable path.
    - Standalone-Application: Creates a package to deploy a standalone application. Use -Path to specify the application directory.
    - WindowsFeature: Creates a package to enable or disable a Windows feature.
    - Custom: Creates a custom configuration package.
    
.DYNAMIC PARAMETER Name
Specifies the name of the application. This is written into the exported configuration files. If you do not provide a name, the script will attempt to generate it.

.DYNAMIC PARAMETER Version
Specifies the version of the application. This is written into the exported configuration files. This should be in the format of x.x.x.x. If you do not provide a version, the script will attempt to extract it from the installer file.

.DYNAMIC PARAMETER Path
Specifies the path to either the main file or directory of a standalone application or executable. This parameter is mandatory for StandAlone-Exe and Standalone-Application ConfigurationTypes.

.DYNAMIC PARAMETER DestinationFolder
Specifies the folder where the output will be created. Default is the current directory.

.DYNAMIC PARAMETER CreateIntuneWinPackage
Switch parameter to create an Intune package for the application. Default is false.

.DYNAMIC PARAMETER IncludedFiles
Specifies an array of files or directories to include in the package.

.DYNAMIC PARAMETER RegistryValue
Specifies the registry key details to create or modify. This should be in the format:
`FullPath,KeyName,KeyType,KeyData,State`
Where:
    - FullPath: The full path to the registry key (e.g., HKEY_LOCAL_MACHINE\Software\MySoftware).
    - KeyName: The name of the registry value.
    - KeyType: The data type of the registry value (e.g., DWORD, String, Binary).
    - KeyData: The data to be written to the registry value.
    - State: ADD, REMOVE, or MODIFY.
Example: "HKEY_LOCAL_MACHINE\Software\MySoftware,MyName,DWORD,1,ADD"
A .csv file will also be created where you can add multiple registry items. Note that any failure of any registry item will cause the whole configuration to fail.

.DYNAMIC PARAMETER Target
Specifies the target for the deployment, User context or System context. Default is 'System'.

.DYNAMIC PARAMETER LauncherName
Specifies the name of the file to launch the application.

.DYNAMIC PARAMETER LauncherRelativePath
Specifies the relative path of the launcher file in the included files directory path.

.DYNAMIC PARAMETER CLIApp
Specifies if the standalone-exe is a CLI application. If true, the executable will be added to the bin directory and the user's PATH environment variable.

.DYNAMIC PARAMETER Files
Specifies a list of files to include in the package.

.DYNAMIC PARAMETER FilesDirectoryName
Specifies the name of the directory where the files will be stored within the package.

.EXAMPLE
New-APFConfigDeployment -ConfigurationType Registry -Name "My Application" -Version "1.0.0.0" -RegistryValue "HKEY_LOCAL_MACHINE\Software\MySoftware,MyValue,String,MyData,ADD"

.EXAMPLE
New-APFConfigDeployment -ConfigurationType Files -Name "My Application" -Version "1.0.0.0" -Files @("C:\file1.txt", "C:\file2.txt") -FilesDirectoryName "MyFiles"

.EXAMPLE
New-APFConfigDeployment -ConfigurationType StandAlone-Exe -Name "MyApp" -Version "1.2.3.4" -Path "C:\path\to\myapp.exe" -CLIApp $true

.NOTES
This function requires the Application Packaging Framework (APF) to be installed.  It uses dynamic parameters, so the parameters available will change based on the ConfigurationType selected.
#>
function New-APFConfigDeployment {
    param(
        [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://NOTEDEFINED/tcs.intune.packaging/docs/New-APFConfigDeployment.html')]
        [OutputType([string])]

        [Parameter(HelpMessage = "The type of configuration this command is for.")]
        [ValidateSet("Registry", "PowerShellProfiles", "Files", "Script-OS", "Script-App", "Script-User", "StandAlone-Exe", "Standalone-Application", "WindowsFeature", "Custom")]
        [string]$ConfigurationType

    )

    DynamicParam {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        # Default Params - doing this so the only default choice is the Configuration Type
        
        $defaults = @(
            @{Name = "Name"; ParameterType = [string]; Mandatory = $true; Position = 1; ValueFromPipelineByPropertyName = $true; HelpMessage = "The name of the application. `nThis is written in to the exported configuration files. `nIf you do not provide a name, the script will attempt to generate it." }
            @{Name = "Version"; ParameterType = [version]; Mandatory = $true; Position = 2; ValueFromPipelineByPropertyName = $true; HelpMessage = "The version of the application. `nThis is written in to the exported configuration files. `nThis should be in the format of x.x.x.x. `nIf you do not provide a version, the script will attempt to extract it from the installer file." }
            @{Name = "Path"; ParameterType = [string]; Mandatory = $true; Position = 3; ValueFromPipelineByPropertyName = $true; HelpMessage = "The Path or either the main file or directory of a standalone application"; ValidateScript = {
                    foreach ($i in $_) {
                        if (-not (Test-Path $i)) {
                            throw "Path $($i) is invalid, double check and try again."
                        }
                    } 
                    return $true
                }
            }
            @{Name = "DestinationFolder"; ParameterType = [string]; ValueFromPipelineByPropertyName = $true; HelpMessage = "The folder where the output will be created. Default is the current directory." }
            @{Name = "CreateIntuneWinPackage"; ParameterType = [switch]; ValueFromPipelineByPropertyName = $true; HelpMessage = "Create a Intune package for the application. Default is false." }
        )
        foreach ($d in $defaults) {
            $param = $(New-DynamicParameter @d)
            $paramDictionary.Add($Param.Name, $Param.Parameter)
        }
        $variableParams = @(
            @{Name = "IncludedFiles"; ParameterType = [string[]]; ValueFromPipelineByPropertyName = $true; HelpMessage = "The Path or either the main file or directory of a standalone application"; ValidateScript = {
                    foreach ($i in $_) {
                        if (-not (Test-Path $i)) {
                            throw "Path $($i) is invalid, double check and try again."
                        }
                    } 
                    return $true
                }
            }
            @{Name = "RegistryValue"; ParameterType = [string]; ValueFromPipelineByPropertyName = $true; HelpMessage = "The registry key details to create or modify. \
                    `nThis should be in the format of fullPath: HKEY_LOCAL_MACHINE\Software\, KeyName: MyKey, KeyType: DWORD, KeyData: Setting1, State: ADD|REMOVE|MODIFY\
                    `nSo you would enter `"HKEY_LOCAL_MACHINE\Software\,MySoftware,MyName,DWORD,Setting1,ADD`" as the value.\
                    `nThere will also be a .csv file created where you can add as many registry items as you like.\
                    `nBare in mind that any failure of any registry item will cause the whole configuration to fail." 
            }
            @{Name = "Target"; ParameterType = [string]; ValidateSet = "System", "User"; HelpMessage = "The target for the deployment, User context or System context. Default is 'system'." }
            @{Name = "LauncherName"; ParameterType = [string]; HelpMessage = "Name of the file to launch the application." }
            @{Name = "LauncherRelativePath"; ParameterType = [string]; HelpMessage = "The relative path of the launcher file in the included files directory path." }
            @{Name = "CLIApp"; ParameterType = [bool]; HelpMessage = "If the standalone-exe is a cli application, add it to the bin directory and ensure it's added to the users PATH." }
            @{Name = "Files"; ParameterType = [string[]]; HelpMessage = "List of files to include in the package."; ValidateScript = {
                    foreach ($i in $_) {
                        if (-not (Test-Path $i)) {
                            throw "Path $($i) is invalid, double check and try again."
                        }
                    }
                    return $true
                }
            }
            @{Name = "FilesDirectoryName"; ParameterType = [string]; Mandatory = $true; HelpMessage = "Name of the directory where the files will be stored." }
        )
        switch -Exact ($ConfigurationType) {
            'registry' {
                $dynamicParamRegistry = @(
                    $variableParams[0]
                    $variableParams[1]
                    $variableParams[2]
                )
                foreach ($d in $dynamicParamRegistry) {
                    $param = $(New-DynamicParameter @d)
                    if (-not $paramDictionary.ContainsKey($param.Name)) {
                        $paramDictionary.Add($Param.Name, $Param.Parameter)
                    }
                }
                break
            }
            { $_ -in 'files', 'powershellprofiles' } {
                $dynamicParamFiles = @(
                    $variableParams[6]
                    $variableParams[7]
                )
                foreach ($d in $dynamicParamFiles) {
                    $param = $(New-DynamicParameter @d)
                    if (-not $paramDictionary.ContainsKey($param.Name)) {
                        $paramDictionary.Add($Param.Name, $Param.Parameter)
                    }
                }
                # IF REMOVING ITEMS FROM AN ARRAY IN A DYNAMIC PARAM BLOCK MAKE SURE TO OUT_NULL AS ANY BOOLEAN VALUE WILL EXIT THE SWITCH
                $paramDictionary.Remove("Path") | Out-Null
                break
            }
            { $_ -in 'script-os', 'script-app', 'script-user', 'windowsfeature' } {
                $dynamicParamScriptOS = @(
                    $variableParams[0]
                    
                )
                foreach ($d in $dynamicParamScriptOS) {
                    $param = $(New-DynamicParameter @d)
                    if (-not $paramDictionary.ContainsKey($param.Name)) {
                        $paramDictionary.Add($Param.Name, $Param.Parameter)
                    }
                }
                # IF REMOVING ITEMS FROM AN ARRAY IN A DYNAMIC PARAM BLOCK MAKE SURE TO OUT_NULL AS ANY BOOLEAN VALUE WILL EXIT THE SWITCH
                $paramDictionary.Remove("Path") | Out-Null
                break
            }
            'standalone-exe' {
                $dynamicParamStandaloneExe = @(
                    $variableParams[0]
                    $variableParams[5]
                    
                )
                foreach ($d in $dynamicParamStandaloneExe) {
                    $param = $(New-DynamicParameter @d)
                    if (-not $paramDictionary.ContainsKey($param.Name)) {
                        $paramDictionary.Add($Param.Name, $Param.Parameter)
                    }
                }
                break
            }
            'standalone-application' {
                $dynamicParamStandaloneApplication = @(
                    $variableParams[0]
                    $variableParams[3]
                    $variableParams[4]                    
                )
                foreach ($d in $dynamicParamStandaloneApplication) {
                    $param = $(New-DynamicParameter @d)
                    if (-not $paramDictionary.ContainsKey($param.Name)) {
                        $paramDictionary.Add($Param.Name, $Param.Parameter)
                    }
                }
                break
            }
            'custom' {
                $dynamicParamCustom = @(
                    $variableParams[0]                   
                )
                foreach ($d in $dynamicParamCustom) {
                    $param = $(New-DynamicParameter @d)
                    if (-not $paramDictionary.ContainsKey($param.Name)) {
                        $paramDictionary.Add($Param.Name, $Param.Parameter)
                    }
                }
                break
            }
            default {
                return
            }
        }
        return $paramDictionary
    }

    begin {
        # Generate execution ID
        $ExecutionID = [System.Guid]::NewGuid().ToString()
        try {
            $CurrentConfig = Get-ModuleConfig -CommandPath $PSCommandPath
            $TelmetryArgs = @{
                ModuleName    = $CurrentConfig.ModuleName
                ModulePath    = $CurrentConfig.ModulePath
                ModuleVersion = $MyInvocation.MyCommand.Module.Version
                ExecutionID   = $ExecutionID
                CommandName   = $MyInvocation.MyCommand.Name
                URI           = 'https://NOTYETDEFINED.com'
            }
            if ($CurrentConfig.BasicTelemetry -eq 'True') {
                $TelmetryArgs.Add('Minimal', $true)
            }
            Invoke-TelemetryCollection @TelmetryArgs -Stage start -ClearTimer
        }
        catch {
            Write-Verbose "Failed to load telemetry"
        }
        # Invoke-TelemetryCollection @TelmetryArgs -Stage End -ClearTimer -Failed $true -Exception $_
        # Invoke-TelemetryCollection @TelmetryArgs -Stage End -ClearTimer

        ## Convert bound params to Variables
        if ([string]::IsNullOrEmpty($($PSBoundParameters['DestinationFolder']))) { $DestinationFolder = $PWD } else { $DestinationFolder = $($PSBoundParameters['DestinationFolder']) }
        $Name = $($PSBoundParameters['Name'])
        $IncludedFiles = $($PSBoundParameters['IncludedFiles'])
        $Version = $($PSBoundParameters['Version'])
        $Path = $($PSBoundParameters['Path'])
        $CreateIntuneWinPackage = $($PSBoundParameters['CreateIntuneWinPackage'])
        $RegistryValue = $($PSBoundParameters['RegistryValue'])
        $Target = $($PSBoundParameters['Target'])
        $LauncherName = $($PSBoundParameters['LauncherName'])
        $LauncherRelativePath = $($PSBoundParameters['LauncherRelativePath'])
        if ([string]::IsNullOrEmpty($($PSBoundParameters['CLIApp'])) -or $([string]::IsNullOrEmpty($($PSBoundParameters['CLIApp'])) -eq "false") ) { $CLIApp = $false } else { $CLIApp = $true }
        $FilesDirectoryName = $($PSBoundParameters['FilesDirectoryName'])
        $Files = $($PSBoundParameters['Files'])
    } 
    Process {

        # Create Switch on ConfigurationType

        switch ($ConfigurationType) {
            "Registry" {
                # Create Registry CSV file and add any commandline provided registry keys
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing folder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }
                $RegistryFile = Join-Path -Path $DestinationFolder -ChildPath "$($Name)_Registry.csv"
                Write-Verbose "Creating registry file at $RegistryFile"
                if (-not (Test-Path $RegistryFile)) {
                    New-Item -Path $RegistryFile -ItemType File | Out-Null
                    Copy-Item -Path "$PSScriptRoot\Templates\Registry\registry_entries.config.csv" -Destination $RegistryFile -Force
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing registry file? Warning: This will delete the existing file.", "Confirm Overwrite")) {
                        Remove-Item -Path $RegistryFile -Force
                        Copy-Item -Path "$PSScriptRoot\Templates\Registry\registry_entries.config.csv" -Destination $RegistryFile
                    }
                }
                if ($RegistryValue) {         
                    # add registry keys to the csv file
                    # Import current file, loop through and check if supplied key is already in the file
                    try {
                        $RegistryKeys = Import-Csv -Path $RegistryFile -ErrorAction Stop
                        $RegistryKeys | ForEach-Object {
                            $exists = $false
                            if ($_ -eq $RegistryValue) {
                                Write-Warning "The registry values supplied '$($RegistryValue)' already exists in the file."
                                $exists = $true
                                return
                            }
                            if ($exists -eq $false) {
                                Export-Csv -Path $RegistryFile -InputObject $RegistryValue -Append -NoTypeInformation
                            }
                        }
                    }
                    catch {
                        Write-Error "Failed to import the supplied entry to the registry file.`nError: $_"
                        break
                    }
                }
                else {
                    Write-Verbose "No registry keys were supplied."
                }

                $IncludeFolder = Join-Path -Path $DestinationFolder -ChildPath "src"
                if (-not (Test-Path $IncludeFolder)) {
                    New-Item -Path $IncludeFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $IncludeFolder -Recurse -Force | Out-Null
                        New-Item -Path $IncludeFolder -ItemType Directory | Out-Null
                    }
                }
                if (-Not [string]::IsNullOrEmpty($IncludedFiles)) {
                    Write-Output "Copying included files.."
                    $count = 0
                    foreach ($file in $IncludedFiles) {
                        $count++
                        Write-Verbose "Copying $($file.Name). [$($count) of $($IncludeFolder.count)]"
                        Copy-Item -Path $file -Destination $DestinationFolder
                    }
                }
                # Copy the template files to the main folder
                try {
                    Copy-Item -Path "$PSScriptRoot\Templates\Registry\*" -Destination $DestinationFolder -Recurse -Exclude *.md, *config.*
                }
                catch {
                    Write-Error "Failed to copy the template files to the main folder.`nError: $_"
                    break
                }

                # Update the template files with the deployment name and version
                $MainConfig = Get-Content -Path "$PSScriptRoot\Templates\Registry\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.target = $Target
                $MainConfig.registryfile = "$($Name)_Registry.csv"
                $MainConfig.packagedby = $env:USERNAME
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"

                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-RegistryDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILENAME_TEMPLATE", (Get-Item -Path $DestinationFolder).Name
                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-RegistryDetection.ps1"
            }
            "PowerShellProfiles" {
                # Copy files to disk from deployment
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    Write-Verbose "Creating package folder $($DestinationFolder)"
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Write-Verbose "Removing existing directory $($DestinationFolder) and recreating.."
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }
                # Copy the template files to the deployment folder
                Write-Verbose "Copying template files to destination folder."
                Copy-Item -Path "$PSScriptRoot\Templates\PowerShellProfile\*" -Destination $DestinationFolder -Recurse

                foreach ($f in $Files) {
                    try {
                        Copy-Item -Path $f -Destination $DestinationFolder -ErrorAction Stop
                    }
                    catch {
                        Write-Error "Failed to copy file $($f) to the destination folder. Error: $_"
                        break
                    }
                }

                # Update the template files with the deployment name and version
                $InstallerFileName = (Get-ChildItem -Path $Path).BaseName
                $MainConfig = Get-Content -Path "$DestinationFolder\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.directory = $FilesDirectoryName
                $MainConfig.files = $(if (-Not [string]::IsNullOrEmpty($Files)) { $Files | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                $MainConfig.packagedby = $env:USERNAME
                Write-Verbose "Modifying template files with template parameters.."
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"

                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILES_TEMPLATE", $($(if (-Not [string]::IsNullOrEmpty($Files)) { $Files | % { $(Get-ChildItem -Path $_).Name } }) -Join ",")

                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
            }
            "Files" {
                # Copy files to disk from deployment
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    Write-Verbose "Creating package folder $($DestinationFolder)"
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Write-Verbose "Removing existing directory $($DestinationFolder) and recreating.."
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }
                # Copy the template files to the application folder
                Write-Verbose "Copying template files to destination folder."
                Copy-Item -Path "$PSScriptRoot\Templates\Files\*" -Destination $DestinationFolder -Recurse

                foreach ($f in $Files) {
                    try {
                        Copy-Item -Path $f -Destination $DestinationFolder -ErrorAction Stop
                    }
                    catch {
                        Write-Error "Failed to copy file $($f) to the destination folder. Error: $_"
                        break
                    }
                }

                # Update the template files with the application name and version
                $InstallerFileName = (Get-ChildItem -Path $Path).BaseName
                $MainConfig = Get-Content -Path "$DestinationFolder\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.directory = $FilesDirectoryName
                $MainConfig.files = $(if (-Not [string]::IsNullOrEmpty($Files)) { $Files | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                $MainConfig.packagedby = $env:USERNAME
                Write-Verbose "Modifying template files with template parameters.."
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"

                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILES_TEMPLATE", $($(if (-Not [string]::IsNullOrEmpty($Files)) { $Files | % { $(Get-ChildItem -Path $_).Name } }) -Join ",")

                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
            }
            "StandAlone-Exe" {
                # Create subfolder for the application
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    Write-Verbose "Creating package folder $($DestinationFolder)"
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the application? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Write-Verbose "Removing existing directory $($DestinationFolder) and recreating.."
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }
                if ($Path) {
                    # Copy the installer file and any additional files to the application folder
                    Copy-Item -Path $Path -Destination $DestinationFolder
                }
                if (-Not [string]::IsNullOrEmpty($IncludedFiles)) {
                    Write-Output "Copying included files.."
                    $count = 0
                    foreach ($file in $IncludedFiles) {
                        $count++
                        Write-Verbose "Copying $($file.Name). [$($count) of $($IncludeFolder.count)]"
                        Copy-Item -Path $file -Destination $DestinationFolder
                    }
                }
                # Copy the template files to the application folder
                Write-Verbose "Copying template files to destination folder."
                Copy-Item -Path "$PSScriptRoot\Templates\standalone-exe\*" -Destination $DestinationFolder -Recurse

                # Update the template files with the application name and version
                $InstallerFileName = (Get-ChildItem -Path $Path).BaseName
                $MainConfig = Get-Content -Path "$DestinationFolder\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.launchername = (Get-ChildItem -Path $Path).Name
                $MainConfig.includedfiles = $(if (-Not [string]::IsNullOrEmpty($IncludedFiles)) { $IncludedFiles | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                $MainConfig.cli = $CLIApp
                $MainConfig.packagedby = $env:USERNAME
                Write-Verbose "Modifying template files with template parameters.."
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"

                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILENAME_TEMPLATE", (Get-ChildItem -Path $Path).Name

                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
            }
            "Script-OS" {
                # Create os modification CSV file
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing folder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }
                $OSConfigFile = Join-Path -Path $DestinationFolder -ChildPath "$($Name)_config.csv"
                Write-Verbose "Creating OSConfig file at $OSConfigFile"
                if (-not (Test-Path $OSConfigFile)) {
                    New-Item -Path $OSConfigFile -ItemType File | Out-Null
                    Copy-Item -Path "$PSScriptRoot\Templates\script-os\os-config_entries.config.csv" -Destination $OSConfigFile -Force
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing OSConfig file? Warning: This will delete the existing file.", "Confirm Overwrite")) {
                        Remove-Item -Path $OSConfigFile -Force
                        Copy-Item -Path "$PSScriptRoot\Templates\script-os\os-config_entries.config.csv" -Destination $OSConfigFile
                    }
                }
                               
                $IncludeFolder = Join-Path -Path $DestinationFolder -ChildPath "src"
                if (-not (Test-Path $IncludeFolder)) {
                    New-Item -Path $IncludeFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $IncludeFolder -Recurse -Force | Out-Null
                        New-Item -Path $IncludeFolder -ItemType Directory | Out-Null
                    }
                }
                if (-Not [string]::IsNullOrEmpty($IncludedFiles)) {
                    Write-Output "Copying included files.."
                    $count = 0
                    foreach ($file in $IncludedFiles) {
                        $count++
                        Write-Verbose "Copying $($file.Name). [$($count) of $($IncludeFolder.count)]"
                        Copy-Item -Path $file -Destination $DestinationFolder
                    }
                }
                # Copy the template files to the main folder
                try {
                    Copy-Item -Path "$PSScriptRoot\Templates\script-os\*" -Destination $DestinationFolder -Recurse -Exclude *.md, *config.*
                }
                catch {
                    Write-Error "Failed to copy the template files to the main folder.`nError: $_"
                    break
                }
                               
                # Update the template files with the deployment name and version
                $MainConfig = Get-Content -Path "$PSScriptRoot\Templates\script-os\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.configfile = "$($Name)_config.csv"
                $MainConfig.includedfiles = $(if (-Not [string]::IsNullOrEmpty($IncludedFiles)) { $IncludedFiles | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                $MainConfig.packagedby = $env:USERNAME
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"
                               
                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-Detection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILENAME_TEMPLATE", (Get-Item -Path $DestinationFolder).Name
                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-Detection.ps1" 
            }
            "Script-App" {
                # Create subfolder for the application
                $AppFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $AppFolder)) {
                    New-Item -Path $AppFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the application? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $AppFolder -Recurse -Force | Out-Null
                        New-Item -Path $AppFolder -ItemType Directory | Out-Null
                    }
                }
                if ($Path) {
                    # Copy the installer file and any additional files to the application folder
                    Copy-Item -Path $Path -Destination $AppFolder
                }
                if (-Not [string]::IsNullOrEmpty($IncludedFiles)) {
                    Write-Output "Copying included files.."
                    $count = 0
                    foreach ($file in $IncludedFiles) {
                        $count++
                        Write-Verbose "Copying $($file.Name). [$($count) of $($IncludeFolder.count)]"
                        Copy-Item -Path $file -Destination $DestinationFolder
                    }
                }
                # Copy the template files to the application folder
                # Copy-Item -Path "$PSScriptRoot\Templates\Application\*" -Destination $AppFolder -Recurse

                # Update the template files with the application name and version
                $InstallerFileName = (Get-ChildItem -Path $Path).BaseName
                $MainConfig = Get-Content -Path "$AppFolder\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.filename = (Get-ChildItem -Path $Path).Name
                $MainConfig.includedfiles = $(if (-Not [string]::IsNullOrEmpty($IncludedFiles)) { $IncludedFiles | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                $MainConfig.installSwitches = $InstallSwitches
                $MainConfig.uninstallSwitches = $UninstallSwitches
                $MainConfig.uninstallPath = $UninstallPath
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$AppFolder\config.installer.json"

                $DetectionScript = Get-Content -Path "$AppFolder\Intune-D-AppDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILENAME_TEMPLATE", (Get-ChildItem -Path $Path).Name
                $DetectionScript | Set-Content -Path "$AppFolder\Intune-D-AppDetection.ps1"
            }
            "Script-User" {
                
            }
            "WindowsFeature" {
                # Create windowsfeatures CSV file
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing folder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }
                $WindowsFeaturesFile = Join-Path -Path $DestinationFolder -ChildPath "$($Name)_config.csv"
                Write-Verbose "Creating windowsfeatures file at $WindowsFeaturesFile"
                if (-not (Test-Path $WindowsFeaturesFile)) {
                    New-Item -Path $WindowsFeaturesFile -ItemType File | Out-Null
                    Copy-Item -Path "$PSScriptRoot\Templates\windowsfeatures\windowsfeatures_entries.config.csv" -Destination $WindowsFeaturesFile -Force
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing windowsfeatures file? Warning: This will delete the existing file.", "Confirm Overwrite")) {
                        Remove-Item -Path $WindowsFeaturesFile -Force
                        Copy-Item -Path "$PSScriptRoot\Templates\windowsfeatures\windowsfeatures_entries.config.csv" -Destination $WindowsFeaturesFile
                    }
                }
                
                $IncludeFolder = Join-Path -Path $DestinationFolder -ChildPath "src"
                if (-not (Test-Path $IncludeFolder)) {
                    New-Item -Path $IncludeFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Remove-Item -Path $IncludeFolder -Recurse -Force | Out-Null
                        New-Item -Path $IncludeFolder -ItemType Directory | Out-Null
                    }
                }
                if (-Not [string]::IsNullOrEmpty($IncludedFiles)) {
                    Write-Output "Copying included files.."
                    $count = 0
                    foreach ($file in $IncludedFiles) {
                        $count++
                        Write-Verbose "Copying $($file.Name). [$($count) of $($IncludeFolder.count)]"
                        Copy-Item -Path $file -Destination $DestinationFolder
                    }
                }
                # Copy the template files to the main folder
                try {
                    Copy-Item -Path "$PSScriptRoot\Templates\windowsfeatures\*" -Destination $DestinationFolder -Recurse -Exclude *.md, *config.*
                }
                catch {
                    Write-Error "Failed to copy the template files to the main folder.`nError: $_"
                    break
                }
                
                # Update the template files with the deployment name and version
                $MainConfig = Get-Content -Path "$PSScriptRoot\Templates\windowsfeatures\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.configfile = "$($Name)_WindowsFeatures.csv"
                $MainConfig.includedfiles = $(if (-Not [string]::IsNullOrEmpty($IncludedFiles)) { $IncludedFiles | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                $MainConfig.packagedby = $env:USERNAME
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"
                
                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-WindowsFeatureDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##FILENAME_TEMPLATE", (Get-Item -Path $DestinationFolder).Name
                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-WindowsFeatureDetection.ps1"
            }
            "Standalone-Application" {
                # Create subfolder for the application
                $DestinationFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
                if (-not (Test-Path $DestinationFolder)) {
                    Write-Verbose "Creating package folder $($DestinationFolder)"
                    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                }
                else {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing subfolder for the application? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                        Write-Verbose "Removing existing directory $($DestinationFolder) and recreating.."
                        Remove-Item -Path $DestinationFolder -Recurse -Force | Out-Null
                        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
                    }
                }

                if (-Not [string]::IsNullOrEmpty($IncludedFiles)) {
                    Write-Output "Copying included files.."
                    $count = 0
                    foreach ($i in $IncludedFiles) {
                        $count++
                        Write-Verbose "Copying $($i.Name). [$($count) of $($IncludeFolder.count)]"
                        if ((Get-Item -Path $i).PSIsContainer) {
                            $ContainerPath = Split-Path -Path $Path -Leaf
                            $DestinationPath = $(Join-Path -Path $DestinationFolder -ChildPath $ContainerPath)
                            New-Item -Path $DestinationPath -ItemType Directory
                            Copy-Item -Path $i -Destination $DestinationPath
                        }
                        else {
                            Copy-Item -Path $i -Destination $DestinationFolder
                        }
                    }
                }
                # Copy the template files to the application folder
                Write-Verbose "Copying template files to destination folder."
                Copy-Item -Path "$PSScriptRoot\Templates\standalone-application\*" -Destination $DestinationFolder -Recurse
                
                # Update the template files with the application name and version
                $InstallerFileName = (Get-ChildItem -Path $Path).BaseName
                $MainConfig = Get-Content -Path "$DestinationFolder\config.installer.json" | ConvertFrom-Json
                $MainConfig.name = $Name
                $MainConfig.version = $Version.ToString()
                $MainConfig.filename = (Get-ChildItem -Path $Path).Name
                $MainConfig.includedfiles = $(if (-Not [string]::IsNullOrEmpty($IncludedFiles)) { $IncludedFiles | % { $(Get-ChildItem -Path $_).Name } }) -Join ","
                Write-Verbose "Modifying template files with template parameters.."
                $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "$DestinationFolder\config.installer.json"
                
                $DetectionScript = Get-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
                $DetectionScript = $DetectionScript -replace "##NAME_TEMPLATE", $Name
                $DetectionScript = $DetectionScript -replace "##VERSION_TEMPLATE", $Version.ToString()
                $DetectionScript = $DetectionScript -replace "##LAUNCHERNAME_TEMPLATE", $LauncherName
                $DetectionScript = $DetectionScript -replace "##LAUNCHERRELATIVEPATH_TEMPLATE", $LauncherRelativePath
                $DetectionScript | Set-Content -Path "$DestinationFolder\Intune-D-AppDetection.ps1"
            }
            "Custom" {
                
            }
        }



        # Create IntuneWin Package
        if ($CreateIntuneWinPackage) {
            try {
                # Get module directory path
                $ModulePath = Split-Path -Path $MyInvocation.MyCommand.Module.Path
                # Test if the IntuneWinAppUtil application exists in module directory
                if (-not (Test-Path "$ModulePath\IntuneWinAppUtil.exe")) {
                    if ($PSCmdlet.ShouldContinue("The IntuneWinAppUtil.exe application was not found in the module directory. Would you like to download it now?", "Download Now?")) {
                        Get-IntunePackagingTool -Path $ModulePath
                    }
                    else {
                        Write-Warning "The IntuneWinAppUtil.exe application is required to create IntuneWin packages. Please download it manually."
                        return
                    }
                } 
                # Create IntuneWin package
                $IntunewinFullPath = Join-Path -Path $DestinationFolder -ChildPath "$InstallerFileName.intunewin"
                $MainInstallerFilePath = Join-Path -Path $AppFolder -ChildPath (Get-Item -Path $Path).Name
                if (Test-Path $IntunewinFullPath) {
                    if ($PSCmdlet.ShouldContinue("Overwrite existing IntuneWin package? Warning: This will delete the existing package.", "Confirm Overwrite")) {
                        Remove-Item -Path $IntunewinFullPath -Force
                    }
                    else {
                        Write-Warning "The IntuneWin package already exists. Please delete it manually or choose a different destination folder."
                        return
                    }
                }
                Start-Process -FilePath "$ModulePath\IntuneWinAppUtil.exe" -ArgumentList "-c `"$AppFolder`"", "-s `"$MainInstallerFilePath`"", "-o `"$DestinationFolder`"" -Wait -NoNewWindow -ErrorAction Stop
                if (-not (Test-Path $IntunewinFullPath)) {
                    throw "$IntuneWinFullPath was not created"
                }
                else {
                    Write-Output "The application '$Name' has been successfully packaged.`nThis can be found in the folder '$AppFolder'."
                    Write-Output "The application '$Name' was also packaged to an intunewin file.`nThis can be found in the folder '$DestinationFolder'."
                }
            }
            catch {
                Write-Error "Failed to create IntuneWin package: $_"
            }
        }
        else {
            Write-Output "The application '$Name' has been successfully packaged.`nThis can be found in the folder '$DestinationFolder'."
        }
        Write-Output "When publishing the application to Intune, use`n'powershell.exe -File Intune-I-MainInstaller.ps1' for the install Command and`n'powershell.exe -File Intune-I-MainInstaller.ps1 -Uninstall' for the Uninstall Command."
    }
}
