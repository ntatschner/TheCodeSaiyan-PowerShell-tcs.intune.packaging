function New-APFConfigDeployment {
    <#
    .SYNOPSIS
        Creates an APF (Application Packaging Framework) configuration deployment package for Intune.

    .DESCRIPTION
        The New-APFConfigDeployment function creates a folder named after the deployment in
        DestinationFolder, copies the matching APF installer templates into it and fills in
        config.installer.json and the detection script. Optionally it also wraps the folder into an
        Intune package ("<Name>.intunewin" in DestinationFolder).

        The parameters available depend on ConfigurationType (they are dynamic parameters):
          - All types: Name, Version, DestinationFolder, CreateIntuneWinPackage.
          - Registry: IncludedFiles, RegistryValue, Target.
          - PowerShellProfiles and Files: Files, FilesDirectoryName.
          - Script-OS and WindowsFeature: IncludedFiles.
          - StandAlone-Exe: Path, IncludedFiles, CLIApp.
          - Standalone-Application: Path, IncludedFiles, LauncherName, LauncherRelativePath.

        Dynamic parameters:
          Name                    The name of the deployment; written into the configuration files and
                                  used as the folder name.
          Version                 The version of the deployment (x.x.x.x).
          Path                    The main file (StandAlone-Exe) or the file or folder of a standalone
                                  application (Standalone-Application).
          DestinationFolder       Where the package folder is created. Default is the current directory.
          CreateIntuneWinPackage  Also create a .intunewin package.
          IncludedFiles           Additional files or folders to include in the package.
          RegistryValue           One registry entry in the format of the registry CSV columns:
                                  "RegistryPath,KeyName,ValueName,ValueType,ValueData,State", for example
                                  "HKLM:\Software,MySoftware,MyValue,String,MyData,ADD". State is ADD,
                                  MODIFY or REMOVE. More entries can be added to the generated
                                  "<Name>_Registry.csv" file. Any failed entry fails the whole deployment.
          Target                  'System' (default) or 'User'.
          LauncherName            The file that launches a standalone application.
          LauncherRelativePath    The relative path of the launcher inside the included files.
          CLIApp                  $true when a standalone executable is a command-line tool; it is then
                                  installed to the APF bin folder that is added to PATH.
          Files                   The files to deploy (PowerShellProfiles and Files).
          FilesDirectoryName      The name of the directory the files are deployed to.

        The types Script-App, Script-User and Custom are reserved and not implemented yet.

    .PARAMETER ConfigurationType
        The type of configuration package to create: Registry, PowerShellProfiles, Files, Script-OS,
        Script-App, Script-User, StandAlone-Exe, Standalone-Application, WindowsFeature or Custom.
        Script-App, Script-User and Custom are not implemented yet and return an error.

    .OUTPUTS
        System.String
        Messages that describe where the package was created and which install commands to use.

    .EXAMPLE
        New-APFConfigDeployment -ConfigurationType Registry -Name "My Settings" -Version "1.0.0.0" -RegistryValue "HKLM:\Software,MySoftware,MyValue,String,MyData,ADD"

        Creates a registry deployment package with one registry entry.

    .EXAMPLE
        New-APFConfigDeployment -ConfigurationType Files -Name "My Files" -Version "1.0.0.0" -Files "C:\file1.txt", "C:\file2.txt" -FilesDirectoryName "MyFiles"

        Creates a package that deploys two files to the MyFiles directory.

    .EXAMPLE
        New-APFConfigDeployment -ConfigurationType StandAlone-Exe -Name "MyApp" -Version "1.2.3.4" -Path "C:\path\to\myapp.exe" -CLIApp $true

        Creates a package that installs myapp.exe as a command-line tool.

    .NOTES
        The generated installer scripts run on Windows devices managed by Intune.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The type of configuration this command is for.")]
        [ValidateSet("Registry", "PowerShellProfiles", "Files", "Script-OS", "Script-App", "Script-User", "StandAlone-Exe", "Standalone-Application", "WindowsFeature", "Custom")]
        [string]$ConfigurationType
    )

    DynamicParam {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        # Default Params - doing this so the only default choice is the Configuration Type
        $PathValidation = {
            foreach ($i in $_) {
                if (-not (Test-Path $i)) {
                    throw "Path $($i) is invalid, double check and try again."
                }
            }
            return $true
        }
        $defaults = @(
            @{Name = "Name"; ParameterType = [string]; Mandatory = $true; Position = 1; ValueFromPipelineByPropertyName = $true; HelpMessage = "The name of the deployment. This is written in to the exported configuration files." }
            @{Name = "Version"; ParameterType = [version]; Mandatory = $true; Position = 2; ValueFromPipelineByPropertyName = $true; HelpMessage = "The version of the deployment in the format x.x.x.x. This is written in to the exported configuration files." }
            @{Name = "Path"; ParameterType = [string]; Mandatory = $true; Position = 3; ValueFromPipelineByPropertyName = $true; HelpMessage = "The Path or either the main file or directory of a standalone application"; ValidateScript = $PathValidation }
            @{Name = "DestinationFolder"; ParameterType = [string]; ValueFromPipelineByPropertyName = $true; HelpMessage = "The folder where the output will be created. Default is the current directory." }
            @{Name = "CreateIntuneWinPackage"; ParameterType = [switch]; ValueFromPipelineByPropertyName = $true; HelpMessage = "Create a Intune package for the application. Default is false." }
        )
        foreach ($d in $defaults) {
            $param = $(New-DynamicParameter @d)
            $paramDictionary.Add($param.Name, $param.Parameter)
        }
        $variableParams = @(
            @{Name = "IncludedFiles"; ParameterType = [string[]]; ValueFromPipelineByPropertyName = $true; HelpMessage = "Additional files or folders to include in the package."; ValidateScript = $PathValidation }
            @{Name = "RegistryValue"; ParameterType = [string]; ValueFromPipelineByPropertyName = $true; HelpMessage = "One registry entry as 'RegistryPath,KeyName,ValueName,ValueType,ValueData,State', for example 'HKLM:\Software,MySoftware,MyValue,String,MyData,ADD'. State is ADD, MODIFY or REMOVE." }
            @{Name = "Target"; ParameterType = [string]; ValidateSet = "System", "User"; HelpMessage = "The target for the deployment, User context or System context. Default is 'System'." }
            @{Name = "LauncherName"; ParameterType = [string]; HelpMessage = "Name of the file to launch the application." }
            @{Name = "LauncherRelativePath"; ParameterType = [string]; HelpMessage = "The relative path of the launcher file in the included files directory path." }
            @{Name = "CLIApp"; ParameterType = [bool]; HelpMessage = "If the standalone-exe is a cli application, add it to the bin directory and ensure it's added to the users PATH." }
            @{Name = "Files"; ParameterType = [string[]]; HelpMessage = "List of files to include in the package."; ValidateScript = $PathValidation }
            @{Name = "FilesDirectoryName"; ParameterType = [string]; Mandatory = $true; HelpMessage = "Name of the directory where the files will be stored." }
        )
        $selected = switch ($ConfigurationType) {
            'Registry' { 0, 1, 2 }
            { $_ -in 'Files', 'PowerShellProfiles' } { 6, 7 }
            { $_ -in 'Script-OS', 'Script-App', 'Script-User', 'WindowsFeature', 'Custom' } { 0 }
            'StandAlone-Exe' { 0, 5 }
            'Standalone-Application' { 0, 3, 4 }
            default { $null }
        }
        if ($null -eq $selected) {
            return
        }
        foreach ($index in $selected) {
            $definition = $variableParams[$index]
            $param = $(New-DynamicParameter @definition)
            if (-not $paramDictionary.ContainsKey($param.Name)) {
                $paramDictionary.Add($param.Name, $param.Parameter)
            }
        }
        if ($ConfigurationType -notin 'StandAlone-Exe', 'Standalone-Application') {
            $null = $paramDictionary.Remove('Path')
        }
        return $paramDictionary
    }

    begin {
        ## Convert bound dynamic params to variables
        $DestinationFolder = $PSBoundParameters['DestinationFolder']
        if ([string]::IsNullOrEmpty($DestinationFolder)) {
            $DestinationFolder = $PWD.Path
        }
        $Name = $PSBoundParameters['Name']
        $Version = $PSBoundParameters['Version']
        $Path = $PSBoundParameters['Path']
        $IncludedFiles = @($PSBoundParameters['IncludedFiles'] | Where-Object { $_ })
        $CreateIntuneWinPackage = [bool]$PSBoundParameters['CreateIntuneWinPackage']
        $RegistryValue = $PSBoundParameters['RegistryValue']
        $Target = $PSBoundParameters['Target']
        if ([string]::IsNullOrEmpty($Target)) {
            $Target = 'System'
        }
        $LauncherName = $PSBoundParameters['LauncherName']
        $LauncherRelativePath = $PSBoundParameters['LauncherRelativePath']
        $CLIApp = [bool]$PSBoundParameters['CLIApp']
        $FilesDirectoryName = $PSBoundParameters['FilesDirectoryName']
        $Files = @($PSBoundParameters['Files'] | Where-Object { $_ })
        $TemplateRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Templates'
        $PackagedBy = [Environment]::UserName

        # Creates the package folder, or asks before deleting and recreating an existing one
        function Initialize-PackageFolder {
            param ([string]$FolderPath)
            if (Test-Path -Path $FolderPath) {
                if ($PSCmdlet.ShouldContinue("Overwrite existing folder '$FolderPath' for the deployment? Warning: This will recursively delete all files in the folder.", "Confirm Overwrite")) {
                    Write-Verbose "Removing existing directory $FolderPath and recreating it."
                    Remove-Item -Path $FolderPath -Recurse -Force -ErrorAction Stop
                    $null = New-Item -Path $FolderPath -ItemType Directory -ErrorAction Stop
                }
            }
            else {
                Write-Verbose "Creating package folder $FolderPath"
                $null = New-Item -Path $FolderPath -ItemType Directory -ErrorAction Stop
            }
        }

        # Sets a value on the imported template configuration, adding the property when it is missing
        function Add-TemplateValue {
            param ($Config, [string]$Property, $Value)
            $Config | Add-Member -NotePropertyName $Property -NotePropertyValue $Value -Force
        }

        function Copy-IncludedItem {
            param ([string[]]$Item, [string]$Destination)
            $count = 0
            foreach ($i in $Item) {
                $count++
                Write-Verbose "Copying $i. [$count of $($Item.Count)]"
                Copy-Item -Path $i -Destination $Destination -Recurse -Force -ErrorAction Stop
            }
        }

        function Edit-DetectionScript {
            param ([string]$ScriptPath, [hashtable]$Replacements)
            $Content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
            foreach ($Key in $Replacements.Keys) {
                $Content = $Content.Replace($Key, [string]$Replacements[$Key])
            }
            Set-Content -Path $ScriptPath -Value $Content -NoNewline -ErrorAction Stop
        }
    }

    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer

        try {
            if ($ConfigurationType -in 'Script-App', 'Script-User', 'Custom') {
                throw [System.NotImplementedException]::new("The configuration type '$ConfigurationType' is not implemented yet.")
            }

            $PackageFolder = Join-Path -Path $DestinationFolder -ChildPath $Name
            if (-not $PSCmdlet.ShouldProcess($PackageFolder, "Create $ConfigurationType deployment package")) {
                Invoke-TelemetryCollection @TelemetryArgs -Stage End
                return
            }
            Initialize-PackageFolder -FolderPath $PackageFolder
            $ConfigPath = Join-Path -Path $PackageFolder -ChildPath 'config.installer.json'
            $SetupFile = Join-Path -Path $PackageFolder -ChildPath 'Intune-I-MainInstaller.ps1'

            switch ($ConfigurationType) {
                "Registry" {
                    $TemplateFolder = Join-Path -Path $TemplateRoot -ChildPath 'Registry'
                    $RegistryFile = Join-Path -Path $PackageFolder -ChildPath "$($Name)_Registry.csv"
                    Write-Verbose "Creating registry file at $RegistryFile"
                    Copy-Item -Path (Join-Path -Path $TemplateFolder -ChildPath 'registry_entries.config.csv') -Destination $RegistryFile -Force -ErrorAction Stop

                    if ($RegistryValue) {
                        # Add the supplied entry to the registry CSV unless it is already there
                        $Header = @((Get-Content -Path $RegistryFile -TotalCount 1).Split(','))
                        $Fields = @($RegistryValue.Split(','))
                        if ($Fields.Count -ne $Header.Count) {
                            throw "RegistryValue must contain $($Header.Count) comma-separated values ($($Header -join ',')); '$RegistryValue' contains $($Fields.Count)."
                        }
                        $Entry = [ordered]@{}
                        for ($i = 0; $i -lt $Header.Count; $i++) {
                            $Entry[$Header[$i]] = $Fields[$i].Trim()
                        }
                        $Entry = [PSCustomObject]$Entry
                        $Existing = @(Import-Csv -Path $RegistryFile -ErrorAction Stop)
                        $Duplicate = $Existing | Where-Object { ($_.PSObject.Properties.Value -join ',') -eq ($Entry.PSObject.Properties.Value -join ',') }
                        if ($Duplicate) {
                            Write-Warning "The registry value '$RegistryValue' already exists in the file."
                        }
                        else {
                            @($Existing) + $Entry | Export-Csv -Path $RegistryFile -NoTypeInformation -Force -ErrorAction Stop
                        }
                    }
                    else {
                        Write-Verbose "No registry keys were supplied."
                    }

                    $IncludeFolder = Join-Path -Path $PackageFolder -ChildPath "src"
                    $null = New-Item -Path $IncludeFolder -ItemType Directory -Force -ErrorAction Stop
                    Copy-IncludedItem -Item $IncludedFiles -Destination $PackageFolder

                    Copy-Item -Path (Join-Path -Path $TemplateFolder -ChildPath '*') -Destination $PackageFolder -Recurse -Exclude '*.md', '*config.*' -ErrorAction Stop

                    $MainConfig = Get-Content -Path (Join-Path -Path $TemplateFolder -ChildPath 'config.installer.json') -Raw -ErrorAction Stop | ConvertFrom-Json
                    Add-TemplateValue -Config $MainConfig -Property 'name' -Value $Name
                    Add-TemplateValue -Config $MainConfig -Property 'version' -Value $Version.ToString()
                    Add-TemplateValue -Config $MainConfig -Property 'target' -Value $Target
                    Add-TemplateValue -Config $MainConfig -Property 'registryfile' -Value "$($Name)_Registry.csv"
                    Add-TemplateValue -Config $MainConfig -Property 'packagedby' -Value $PackagedBy
                    $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -ErrorAction Stop

                    Edit-DetectionScript -ScriptPath (Join-Path -Path $PackageFolder -ChildPath 'Intune-D-RegistryDetection.ps1') -Replacements @{
                        '##NAME_TEMPLATE'    = $Name
                        '##VERSION_TEMPLATE' = $Version.ToString()
                    }
                }
                { $_ -in "PowerShellProfiles", "Files" } {
                    $TemplateFolder = Join-Path -Path $TemplateRoot -ChildPath $(if ($ConfigurationType -eq 'Files') { 'Files' } else { 'PowerShellProfile' })
                    Write-Verbose "Copying template files to destination folder."
                    Copy-Item -Path (Join-Path -Path $TemplateFolder -ChildPath '*') -Destination $PackageFolder -Recurse -ErrorAction Stop
                    Copy-IncludedItem -Item $Files -Destination $PackageFolder

                    $FileNames = @($Files | ForEach-Object { Split-Path -Path $_ -Leaf }) -join ','
                    $MainConfig = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
                    Add-TemplateValue -Config $MainConfig -Property 'name' -Value $Name
                    Add-TemplateValue -Config $MainConfig -Property 'version' -Value $Version.ToString()
                    Add-TemplateValue -Config $MainConfig -Property 'target' -Value 'system'
                    Add-TemplateValue -Config $MainConfig -Property 'directory' -Value $FilesDirectoryName
                    Add-TemplateValue -Config $MainConfig -Property 'files' -Value $FileNames
                    Add-TemplateValue -Config $MainConfig -Property 'packagedby' -Value $PackagedBy
                    Write-Verbose "Modifying template files with template parameters."
                    $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -ErrorAction Stop

                    Edit-DetectionScript -ScriptPath (Join-Path -Path $PackageFolder -ChildPath 'Intune-D-AppDetection.ps1') -Replacements @{
                        '##NAME_TEMPLATE'    = $Name
                        '##VERSION_TEMPLATE' = $Version.ToString()
                        '##FILES_TEMPLATE'   = $FileNames
                    }
                }
                "StandAlone-Exe" {
                    Copy-Item -Path $Path -Destination $PackageFolder -ErrorAction Stop
                    Copy-IncludedItem -Item $IncludedFiles -Destination $PackageFolder
                    Write-Verbose "Copying template files to destination folder."
                    Copy-Item -Path (Join-Path -Path (Join-Path -Path $TemplateRoot -ChildPath 'standalone-exe') -ChildPath '*') -Destination $PackageFolder -Recurse -ErrorAction Stop

                    $FileName = Split-Path -Path $Path -Leaf
                    $MainConfig = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
                    Add-TemplateValue -Config $MainConfig -Property 'name' -Value $Name
                    Add-TemplateValue -Config $MainConfig -Property 'version' -Value $Version.ToString()
                    # The installer script reads the executable name from 'filename'
                    Add-TemplateValue -Config $MainConfig -Property 'filename' -Value $FileName
                    Add-TemplateValue -Config $MainConfig -Property 'includedfiles' -Value (@($IncludedFiles | ForEach-Object { Split-Path -Path $_ -Leaf }) -join ',')
                    Add-TemplateValue -Config $MainConfig -Property 'cli' -Value $CLIApp
                    Add-TemplateValue -Config $MainConfig -Property 'packagedby' -Value $PackagedBy
                    Write-Verbose "Modifying template files with template parameters."
                    $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -ErrorAction Stop

                    Edit-DetectionScript -ScriptPath (Join-Path -Path $PackageFolder -ChildPath 'Intune-D-AppDetection.ps1') -Replacements @{
                        '##NAME_TEMPLATE'     = $Name
                        '##VERSION_TEMPLATE'  = $Version.ToString()
                        '##FILENAME_TEMPLATE' = $FileName
                    }
                }
                { $_ -in "Script-OS", "WindowsFeature" } {
                    if ($ConfigurationType -eq 'Script-OS') {
                        $TemplateFolder = Join-Path -Path $TemplateRoot -ChildPath 'script-os'
                        $EntriesTemplate = 'os-config_entries.config.csv'
                        $DetectionFile = 'Intune-D-Detection.ps1'
                    }
                    else {
                        $TemplateFolder = Join-Path -Path $TemplateRoot -ChildPath 'WindowsFeatures'
                        $EntriesTemplate = 'windowsfeatures_entries.config.csv'
                        $DetectionFile = 'Intune-D-WindowsFeatureDetection.ps1'
                    }
                    # The installer scripts read "<Name>_config.csv"
                    $ConfigFileName = "$($Name)_config.csv"
                    $ConfigFile = Join-Path -Path $PackageFolder -ChildPath $ConfigFileName
                    Write-Verbose "Creating configuration file at $ConfigFile"
                    Copy-Item -Path (Join-Path -Path $TemplateFolder -ChildPath $EntriesTemplate) -Destination $ConfigFile -Force -ErrorAction Stop

                    $IncludeFolder = Join-Path -Path $PackageFolder -ChildPath "src"
                    $null = New-Item -Path $IncludeFolder -ItemType Directory -Force -ErrorAction Stop
                    Copy-IncludedItem -Item $IncludedFiles -Destination $PackageFolder

                    Copy-Item -Path (Join-Path -Path $TemplateFolder -ChildPath '*') -Destination $PackageFolder -Recurse -Exclude '*.md', '*config.*' -ErrorAction Stop

                    $MainConfig = Get-Content -Path (Join-Path -Path $TemplateFolder -ChildPath 'config.installer.json') -Raw -ErrorAction Stop | ConvertFrom-Json
                    Add-TemplateValue -Config $MainConfig -Property 'name' -Value $Name
                    Add-TemplateValue -Config $MainConfig -Property 'version' -Value $Version.ToString()
                    Add-TemplateValue -Config $MainConfig -Property 'configfile' -Value $ConfigFileName
                    Add-TemplateValue -Config $MainConfig -Property 'includedfiles' -Value (@($IncludedFiles | ForEach-Object { Split-Path -Path $_ -Leaf }) -join ',')
                    Add-TemplateValue -Config $MainConfig -Property 'packagedby' -Value $PackagedBy
                    $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -ErrorAction Stop

                    Edit-DetectionScript -ScriptPath (Join-Path -Path $PackageFolder -ChildPath $DetectionFile) -Replacements @{
                        '##NAME_TEMPLATE'    = $Name
                        '##VERSION_TEMPLATE' = $Version.ToString()
                    }
                }
                "Standalone-Application" {
                    Copy-Item -Path $Path -Destination $PackageFolder -Recurse -ErrorAction Stop
                    Copy-IncludedItem -Item $IncludedFiles -Destination $PackageFolder
                    Write-Verbose "Copying template files to destination folder."
                    Copy-Item -Path (Join-Path -Path (Join-Path -Path $TemplateRoot -ChildPath 'standalone-application') -ChildPath '*') -Destination $PackageFolder -Recurse -Exclude '*.md' -ErrorAction Stop

                    $MainConfig = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
                    Add-TemplateValue -Config $MainConfig -Property 'name' -Value $Name
                    Add-TemplateValue -Config $MainConfig -Property 'version' -Value $Version.ToString()
                    # The installer script reads the deployed item from 'filename'
                    Add-TemplateValue -Config $MainConfig -Property 'filename' -Value (Split-Path -Path $Path -Leaf)
                    Add-TemplateValue -Config $MainConfig -Property 'launchername' -Value ([string]$LauncherName)
                    Add-TemplateValue -Config $MainConfig -Property 'launcherrelativepath' -Value ([string]$LauncherRelativePath)
                    Add-TemplateValue -Config $MainConfig -Property 'includedfiles' -Value (@($IncludedFiles | ForEach-Object { Split-Path -Path $_ -Leaf }) -join ',')
                    Write-Verbose "Modifying template files with template parameters."
                    $MainConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -ErrorAction Stop

                    Edit-DetectionScript -ScriptPath (Join-Path -Path $PackageFolder -ChildPath 'Intune-D-AppDetection.ps1') -Replacements @{
                        '##NAME_TEMPLATE'                 = $Name
                        '##VERSION_TEMPLATE'              = $Version.ToString()
                        '##LAUNCHERNAME_TEMPLATE'         = $LauncherName
                        '##LAUNCHERRELATIVEPATH_TEMPLATE' = $LauncherRelativePath
                    }
                }
            }

            Write-Output "The deployment '$Name' has been successfully packaged.`nThis can be found in the folder '$PackageFolder'."
            if ($CreateIntuneWinPackage) {
                $Package = New-APFIntuneWinPackage -SourceFolder $PackageFolder -SetupFile $SetupFile -OutputFolder $DestinationFolder -PackageName $Name -ErrorAction Stop
                if ($Package) {
                    Write-Output "The deployment '$Name' was also packaged to an intunewin file.`nThis can be found at '$($Package.FullName)'."
                }
            }
            Write-Output "When publishing the deployment to Intune, use`n'powershell.exe -ExecutionPolicy RemoteSigned -File Intune-I-MainInstaller.ps1' for the install Command and`n'powershell.exe -ExecutionPolicy RemoteSigned -File Intune-I-MainInstaller.ps1 -Uninstall' for the Uninstall Command."
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            Write-Error -Message "Failed to create the $ConfigurationType deployment package: $($_.Exception.Message)" -Exception $_.Exception
        }
    }
}
