BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force

    # Returns the string assigned to a variable in a script, read from the parsed script (not by running it)
    function Get-AssignedString {
        param([string]$Path, [string]$Variable)
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        $errors | Should -BeNullOrEmpty
        $assignment = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.VariablePath.UserPath -eq $Variable
            }, $true)
        $assignment.Right.Expression | Should -BeOfType ([System.Management.Automation.Language.StringConstantExpressionAst])
        $assignment.Right.Expression.Value
    }
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}
Describe 'New-APFConfigDeployment' {
    BeforeEach {
        $Destination = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Destination -ItemType Directory
    }

    Context 'Registry' {
        It 'Creates the registry package and adds the supplied registry value to the CSV file' {
            $null = New-APFConfigDeployment -ConfigurationType Registry -Name 'RegPkg' -Version '1.0.0.0' -DestinationFolder $Destination -RegistryValue 'HKLM:\Software,MySoftware,MyValue,String,MyData,ADD' -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'RegPkg'
            $rows = @(Import-Csv -Path (Join-Path -Path $folder -ChildPath 'RegPkg_Registry.csv'))
            $rows.Count | Should -Be 1
            $rows[0].RegistryPath | Should -Be 'HKLM:\Software'
            $rows[0].ValueName | Should -Be 'MyValue'
            $rows[0].ValueType | Should -Be 'String'
            $rows[0].State | Should -Be 'ADD'
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.name | Should -Be 'RegPkg'
            $config.target | Should -Be 'System'
            $config.registryfile | Should -Be 'RegPkg_Registry.csv'
            Join-Path -Path $folder -ChildPath 'Intune-I-MainInstaller.ps1' | Should -Exist
            Join-Path -Path $folder -ChildPath 'README.md' | Should -Not -Exist
            (Get-Content -Path (Join-Path -Path $folder -ChildPath 'Intune-D-RegistryDetection.ps1') -Raw) | Should -Match "\`$AppName = 'RegPkg'"
        }

        It 'Rejects a registry value with the wrong number of fields' {
            $null = New-APFConfigDeployment -ConfigurationType Registry -Name 'BadReg' -Version '1.0' -DestinationFolder $Destination -RegistryValue 'HKLM:\Software,Only,Three' -ErrorVariable regError -ErrorAction SilentlyContinue -Confirm:$false
            "$regError" | Should -Match 'comma-separated values'
        }
    }

    Context 'Files' {
        It 'Copies the files and records their names' {
            $file = Join-Path -Path $TestDrive -ChildPath 'settings.json'
            Set-Content -Path $file -Value '{}'
            $null = New-APFConfigDeployment -ConfigurationType Files -Name 'FilePkg' -Version '2.0' -DestinationFolder $Destination -Files $file -FilesDirectoryName 'MyFiles' -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'FilePkg'
            Join-Path -Path $folder -ChildPath 'settings.json' | Should -Exist
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.files | Should -Be 'settings.json'
            $config.directory | Should -Be 'MyFiles'
            $config.version | Should -Be '2.0'
        }
    }

    Context 'StandAlone-Exe' {
        It 'Writes the executable name to the filename setting read by the installer and keeps CLIApp false' {
            $exe = Join-Path -Path $TestDrive -ChildPath 'tool.exe'
            Set-Content -Path $exe -Value 'x'
            $null = New-APFConfigDeployment -ConfigurationType StandAlone-Exe -Name 'ToolPkg' -Version '1.0' -Path $exe -CLIApp $false -DestinationFolder $Destination -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'ToolPkg'
            Join-Path -Path $folder -ChildPath 'tool.exe' | Should -Exist
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.filename | Should -Be 'tool.exe'
            $config.cli | Should -BeFalse
        }

        It 'Sets cli to true for command-line tools' {
            $exe = Join-Path -Path $TestDrive -ChildPath 'cli.exe'
            Set-Content -Path $exe -Value 'x'
            $null = New-APFConfigDeployment -ConfigurationType StandAlone-Exe -Name 'CliPkg' -Version '1.0' -Path $exe -CLIApp $true -DestinationFolder $Destination -Confirm:$false
            (Get-Content -Path (Join-Path -Path $Destination -ChildPath 'CliPkg/config.installer.json') -Raw | ConvertFrom-Json).cli | Should -BeTrue
        }
    }

    Context 'WindowsFeature and Script-OS' {
        It 'Creates the <Type> package with the configuration file name the installer reads' -ForEach @(
            @{ Type = 'WindowsFeature'; Detection = 'Intune-D-WindowsFeatureDetection.ps1' }
            @{ Type = 'Script-OS'; Detection = 'Intune-D-Detection.ps1' }
        ) {
            $null = New-APFConfigDeployment -ConfigurationType $Type -Name 'CfgPkg' -Version '1.0' -DestinationFolder $Destination -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'CfgPkg'
            Join-Path -Path $folder -ChildPath 'CfgPkg_config.csv' | Should -Exist
            Join-Path -Path $folder -ChildPath $Detection | Should -Exist
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.configfile | Should -Be 'CfgPkg_config.csv'
            $config.name | Should -Be 'CfgPkg'
        }
    }

    Context 'Standalone-Application' {
        It 'Copies the application folder and fills in the launcher details' {
            $app = Join-Path -Path $TestDrive -ChildPath 'PortableApp'
            $null = New-Item -Path (Join-Path -Path $app -ChildPath 'bin') -ItemType Directory -Force
            Set-Content -Path (Join-Path -Path $app -ChildPath 'bin/app.exe') -Value 'x'
            $null = New-APFConfigDeployment -ConfigurationType Standalone-Application -Name 'AppPkg' -Version '1.0' -Path $app -LauncherName 'app.exe' -LauncherRelativePath 'bin' -DestinationFolder $Destination -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'AppPkg'
            Join-Path -Path $folder -ChildPath 'PortableApp/bin/app.exe' | Should -Exist
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.filename | Should -Be 'PortableApp'
            $config.launchername | Should -Be 'app.exe'
        }
    }

    Context 'Script packages' {
        BeforeEach {
            $DeployScript = Join-Path -Path $TestDrive -ChildPath 'deploy.ps1'
            Set-Content -Path $DeployScript -Value 'exit 0'
        }

        It 'Creates a <Type> package that runs the supplied script as <Target>' -ForEach @(
            @{ Type = 'Script-App'; Target = 'system' }
            @{ Type = 'Script-User'; Target = 'user' }
        ) {
            $extra = Join-Path -Path $TestDrive -ChildPath 'settings.xml'
            Set-Content -Path $extra -Value '<x/>'
            $null = New-APFConfigDeployment -ConfigurationType $Type -Name 'ScriptPkg' -Version '1.0' -Path $DeployScript -IncludedFiles $extra -DestinationFolder $Destination -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'ScriptPkg'
            foreach ($file in 'deploy.ps1', 'settings.xml', 'Intune-I-MainInstaller.ps1', 'Intune-D-Detection.ps1', 'Intune-Pre-Install.ps1', 'Intune-Post-Install.ps1', 'Write-DeploymentLog.ps1') {
                Join-Path -Path $folder -ChildPath $file | Should -Exist
            }
            Join-Path -Path $folder -ChildPath 'Intune-Custom.ps1' | Should -Not -Exist
            Join-Path -Path $folder -ChildPath 'README.md' | Should -Not -Exist
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.scriptfile | Should -Be 'deploy.ps1'
            $config.target | Should -Be $Target
            $config.includedfiles | Should -Be 'settings.xml'
            $config.version | Should -Be '1.0'
            (Get-Content -Path (Join-Path -Path $folder -ChildPath 'Intune-D-Detection.ps1') -Raw) | Should -Match "\`$AppName = 'ScriptPkg'"
        }

        It 'Rejects a deployment script that is not a .ps1 file' {
            $cmd = Join-Path -Path $TestDrive -ChildPath 'deploy.cmd'
            Set-Content -Path $cmd -Value 'x'
            $null = New-APFConfigDeployment -ConfigurationType Script-App -Name 'Bad' -Version '1.0' -Path $cmd -DestinationFolder $Destination -ErrorVariable apfError -ErrorAction SilentlyContinue -Confirm:$false
            "$apfError" | Should -Match '\.ps1'
        }

        It 'Creates a Custom package with the placeholder script and the chosen target' {
            $null = New-APFConfigDeployment -ConfigurationType Custom -Name 'CustomPkg' -Version '2.0' -Target User -DestinationFolder $Destination -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath 'CustomPkg'
            Join-Path -Path $folder -ChildPath 'Intune-Custom.ps1' | Should -Exist
            $config = Get-Content -Path (Join-Path -Path $folder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
            $config.scriptfile | Should -Be 'Intune-Custom.ps1'
            $config.target | Should -Be 'user'
        }
    }

    Context 'Common behaviour' {
        It 'Creates nothing with -WhatIf' {
            $null = New-APFConfigDeployment -ConfigurationType Registry -Name 'WhatIfPkg' -Version '1.0' -DestinationFolder $Destination -WhatIf
            Join-Path -Path $Destination -ChildPath 'WhatIfPkg' | Should -Not -Exist
        }

        It 'Passes the package folder and main installer to the intunewin helper' {
            Mock -ModuleName tcs.intune.packaging New-APFIntuneWinPackage { [System.IO.FileInfo](Join-Path -Path $OutputFolder -ChildPath "$PackageName.intunewin") }
            $output = New-APFConfigDeployment -ConfigurationType Registry -Name 'WinPkg' -Version '1.0' -DestinationFolder $Destination -CreateIntuneWinPackage -Confirm:$false
            Should -Invoke -ModuleName tcs.intune.packaging New-APFIntuneWinPackage -Times 1 -Exactly -ParameterFilter {
                $SourceFolder -eq (Join-Path -Path $Destination -ChildPath 'WinPkg') -and
                $SetupFile -eq (Join-Path -Path (Join-Path -Path $Destination -ChildPath 'WinPkg') -ChildPath 'Intune-I-MainInstaller.ps1') -and
                $PackageName -eq 'WinPkg'
            }
            $output -join "`n" | Should -Match 'WinPkg\.intunewin'
        }
    }

    Context 'Pipeline input' {
        It 'Creates one package per piped object and never touches the destination folder itself' {
            Set-Content -Path (Join-Path -Path $Destination -ChildPath 'keep.txt') -Value 'keep'
            Mock -ModuleName tcs.intune.packaging Confirm-FolderOverwrite { $true }
            $null = @(
                [PSCustomObject]@{ Name = 'PipeOne'; Version = '1.0.0.0' }
                [PSCustomObject]@{ Name = 'PipeTwo'; Version = '2.0.0.0' }
            ) | New-APFConfigDeployment -ConfigurationType Custom -DestinationFolder $Destination -Confirm:$false
            Join-Path -Path $Destination -ChildPath 'keep.txt' | Should -Exist
            (Get-Content -Path (Join-Path -Path $Destination -ChildPath 'PipeOne/config.installer.json') -Raw | ConvertFrom-Json).version | Should -Be '1.0.0.0'
            (Get-Content -Path (Join-Path -Path $Destination -ChildPath 'PipeTwo/config.installer.json') -Raw | ConvertFrom-Json).version | Should -Be '2.0.0.0'
            Should -Invoke -ModuleName tcs.intune.packaging Confirm-FolderOverwrite -Times 0 -Exactly
        }

        It 'Reads DestinationFolder from each piped object' {
            $other = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
            $null = New-Item -Path $other -ItemType Directory
            $null = [PSCustomObject]@{ Name = 'PipeDest'; Version = '1.0'; DestinationFolder = $other } |
                New-APFConfigDeployment -ConfigurationType Custom -Confirm:$false
            Join-Path -Path $other -ChildPath 'PipeDest/Intune-Custom.ps1' | Should -Exist
        }
    }

    Context 'Existing package folder' {
        BeforeEach {
            $existing = Join-Path -Path $Destination -ChildPath 'Existing'
            $null = New-Item -Path $existing -ItemType Directory
            Set-Content -Path (Join-Path -Path $existing -ChildPath 'old.txt') -Value 'old'
        }

        It 'Leaves the folder unchanged and skips the package when the overwrite is declined' {
            Mock -ModuleName tcs.intune.packaging Confirm-FolderOverwrite { $false }
            Mock -ModuleName tcs.intune.packaging New-APFIntuneWinPackage { }
            $output = New-APFConfigDeployment -ConfigurationType Custom -Name 'Existing' -Version '1.0' -DestinationFolder $Destination -CreateIntuneWinPackage -Confirm:$false -WarningVariable apfWarning -WarningAction SilentlyContinue
            Join-Path -Path $existing -ChildPath 'old.txt' | Should -Exist
            Join-Path -Path $existing -ChildPath 'config.installer.json' | Should -Not -Exist
            "$apfWarning" | Should -Match 'was not changed'
            $output | Should -BeNullOrEmpty
            Should -Invoke -ModuleName tcs.intune.packaging New-APFIntuneWinPackage -Times 0 -Exactly
        }

        It 'Recreates the folder when the overwrite is confirmed' {
            Mock -ModuleName tcs.intune.packaging Confirm-FolderOverwrite { $true }
            $null = New-APFConfigDeployment -ConfigurationType Custom -Name 'Existing' -Version '1.0' -DestinationFolder $Destination -Confirm:$false
            Join-Path -Path $existing -ChildPath 'old.txt' | Should -Not -Exist
            Join-Path -Path $existing -ChildPath 'config.installer.json' | Should -Exist
        }
    }

    Context 'Names with special characters' {
        It 'Writes a name with quotes, a subexpression and dots into a detection script that parses' {
            $name = "O'Brien `$(Get-Date) v1..2"
            $null = New-APFConfigDeployment -ConfigurationType Custom -Name $name -Version '1.0' -DestinationFolder $Destination -Confirm:$false
            $folder = Join-Path -Path $Destination -ChildPath $name
            Test-Path -LiteralPath $folder -PathType Container | Should -BeTrue
            @(Get-ChildItem -LiteralPath $Destination).Count | Should -Be 1
            Get-AssignedString -Path (Join-Path -Path $folder -ChildPath 'Intune-D-Detection.ps1') -Variable 'AppName' | Should -BeExactly $name
            Get-AssignedString -Path (Join-Path -Path $folder -ChildPath 'Intune-D-Detection.ps1') -Variable 'Version' | Should -BeExactly '1.0'
        }

        It 'Writes the name into every detection template it fills in (<Type>)' -ForEach @(
            @{ Type = 'Registry'; Detection = 'Intune-D-RegistryDetection.ps1' }
            @{ Type = 'Script-OS'; Detection = 'Intune-D-Detection.ps1' }
            @{ Type = 'WindowsFeature'; Detection = 'Intune-D-WindowsFeatureDetection.ps1' }
            @{ Type = 'Custom'; Detection = 'Intune-D-Detection.ps1' }
        ) {
            $name = "It's `$(x) `"quoted`""
            # A double quote is not allowed in a folder name, so only the template text is checked here
            $template = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
            $moduleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
            $source = Get-ChildItem -Path (Join-Path -Path $moduleRoot -ChildPath 'Public/Templates') -Recurse -Filter $Detection | Select-Object -First 1
            Copy-Item -Path $source.FullName -Destination $template
            InModuleScope tcs.intune.packaging -Parameters @{ Template = $template; Name = $name } {
                Set-TemplateToken -Path $Template -Values @{ NAME = $Name; VERSION = '1.0' }
            }
            Get-AssignedString -Path $template -Variable 'AppName' | Should -BeExactly $name
        }

        It 'Rejects the name <Name>' -ForEach @(
            @{ Name = '..' }
            @{ Name = '.' }
            @{ Name = '../Outside' }
            @{ Name = 'a\b' }
            @{ Name = 'Wild[1]' }
            @{ Name = 'Star*' }
            @{ Name = 'Quote"d' }
            @{ Name = 'Trailing.' }
        ) {
            $null = New-APFConfigDeployment -ConfigurationType Custom -Name $Name -Version '1.0' -DestinationFolder $Destination -Confirm:$false -ErrorVariable apfError -ErrorAction SilentlyContinue
            $apfError | Should -Not -BeNullOrEmpty
            @(Get-ChildItem -LiteralPath $Destination).Count | Should -Be 0
            Join-Path -Path (Split-Path -Path $Destination -Parent) -ChildPath 'Outside' | Should -Not -Exist
        }
    }
}
