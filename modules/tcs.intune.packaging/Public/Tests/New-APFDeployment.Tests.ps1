BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}
Describe 'New-APFDeployment' {
    BeforeEach {
        $Destination = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Destination -ItemType Directory
        $Installer = Join-Path -Path $TestDrive -ChildPath 'Setup.exe'
        Set-Content -Path $Installer -Value 'installer'
    }

    It 'Creates the package folder with the installer, templates and filled-in configuration' {
        $output = New-APFDeployment -Path $Installer -Name 'My App' -Version '1.2.3.4' -InstallSwitches '/S' -UninstallSwitches '/U' -DestinationFolder $Destination -Confirm:$false
        $appFolder = Join-Path -Path $Destination -ChildPath 'My App'
        Join-Path -Path $appFolder -ChildPath 'Setup.exe' | Should -Exist
        Join-Path -Path $appFolder -ChildPath 'Intune-I-MainInstaller.ps1' | Should -Exist
        $config = Get-Content -Path (Join-Path -Path $appFolder -ChildPath 'config.installer.json') -Raw | ConvertFrom-Json
        $config.name | Should -Be 'My App'
        $config.version | Should -Be '1.2.3.4'
        $config.filename | Should -Be 'Setup.exe'
        $config.target | Should -Be 'system'
        $config.installswitches | Should -Be '/S'
        $config.uninstallswitches | Should -Be '/U'
        $detection = Get-Content -Path (Join-Path -Path $appFolder -ChildPath 'Intune-D-AppDetection.ps1') -Raw
        $detection | Should -Match "\`$AppName = 'My App'"
        $detection | Should -Match "\`$Version = '1\.2\.3\.4'"
        $output -join "`n" | Should -Match 'successfully packaged'
    }

    It 'Uses the file name as the default application name for EXE installers' {
        $null = New-APFDeployment -Path $Installer -Version '1.0' -DestinationFolder $Destination -Confirm:$false
        Join-Path -Path $Destination -ChildPath 'Setup' | Should -Exist
    }

    It 'Writes an error when the version cannot be read from the EXE' {
        $null = New-APFDeployment -Path $Installer -DestinationFolder $Destination -ErrorVariable apfError -ErrorAction SilentlyContinue -Confirm:$false
        $apfError | Should -Not -BeNullOrEmpty
        "$apfError" | Should -Match 'Specify it with -Version'
    }

    It 'Supports -WhatIf' {
        $null = New-APFDeployment -Path $Installer -Name 'WhatIfApp' -Version '1.0' -DestinationFolder $Destination -WhatIf
        Join-Path -Path $Destination -ChildPath 'WhatIfApp' | Should -Not -Exist
    }

    It 'Rejects installers that are not MSI or EXE files' {
        $zip = Join-Path -Path $TestDrive -ChildPath 'setup.zip'
        Set-Content -Path $zip -Value 'x'
        { New-APFDeployment -Path $zip -Name 'x' -Version '1.0' -DestinationFolder $Destination } | Should -Throw '*Only .msi and .exe*'
    }

    It 'Creates the intunewin package with the shared helper when requested' {
        Mock -ModuleName tcs.intune.packaging New-APFIntuneWinPackage { [System.IO.FileInfo](Join-Path -Path $OutputFolder -ChildPath 'Setup.intunewin') }
        $output = New-APFDeployment -Path $Installer -Name 'Pkg' -Version '1.0' -DestinationFolder $Destination -CreateIntuneWinPackage -Confirm:$false
        Should -Invoke -ModuleName tcs.intune.packaging New-APFIntuneWinPackage -Times 1 -Exactly -ParameterFilter {
            $SourceFolder -eq (Join-Path -Path $Destination -ChildPath 'Pkg') -and $OutputFolder -eq $Destination
        }
        $output -join "`n" | Should -Match 'Setup\.intunewin'
    }

    It 'Leaves an existing folder unchanged when the overwrite is declined' {
        $existing = Join-Path -Path $Destination -ChildPath 'Existing'
        $null = New-Item -Path $existing -ItemType Directory
        Set-Content -Path (Join-Path -Path $existing -ChildPath 'old.txt') -Value 'old'
        Mock -ModuleName tcs.intune.packaging Confirm-FolderOverwrite { $false }
        $output = New-APFDeployment -Path $Installer -Name 'Existing' -Version '1.0' -DestinationFolder $Destination -Confirm:$false -WarningVariable apfWarning -WarningAction SilentlyContinue
        Join-Path -Path $existing -ChildPath 'old.txt' | Should -Exist
        Join-Path -Path $existing -ChildPath 'Setup.exe' | Should -Not -Exist
        "$apfWarning" | Should -Match 'was not changed'
        $output | Should -BeNullOrEmpty
    }

    It 'Writes a name with quotes and a subexpression into a detection script that parses' {
        $name = "O'Brien `$(Get-Date)"
        $null = New-APFDeployment -Path $Installer -Name $name -Version '1.0' -DestinationFolder $Destination -Confirm:$false
        $script = Join-Path -Path (Join-Path -Path $Destination -ChildPath $name) -ChildPath 'Intune-D-AppDetection.ps1'
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
        $errors | Should -BeNullOrEmpty
        $assignment = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.VariablePath.UserPath -eq 'AppName' }, $true)
        $assignment.Right.Expression.Value | Should -BeExactly $name
    }

    It 'Rejects a name that would leave the destination folder' {
        $null = New-APFDeployment -Path $Installer -Name '..' -Version '1.0' -DestinationFolder $Destination -Confirm:$false -ErrorVariable apfError -ErrorAction SilentlyContinue
        "$apfError" | Should -Match 'not a valid name'
        @(Get-ChildItem -LiteralPath $Destination).Count | Should -Be 0
    }
}
