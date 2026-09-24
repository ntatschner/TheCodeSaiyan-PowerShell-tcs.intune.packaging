BeforeDiscovery {
    $TemplateRoot = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'modules/tcs.intune.packaging/Public/Templates'
    $Scripts = @(Get-ChildItem -Path $TemplateRoot -Recurse -Filter '*.ps1' | ForEach-Object { @{ Name = "$($_.Directory.Name)/$($_.Name)"; Path = $_.FullName } })
    $Configs = @(Get-ChildItem -Path $TemplateRoot -Recurse -Filter 'config.installer.json' | ForEach-Object { @{ Name = $_.Directory.Name; Path = $_.FullName } })
    $Folders = @(Get-ChildItem -Path $TemplateRoot -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } })
}

BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $TemplateRoot = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'modules/tcs.intune.packaging/Public/Templates'
    Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'modules/tcs.intune.packaging/tcs.intune.packaging.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}

Describe 'Installer template <Name>' -ForEach $Scripts {
    It 'Parses without errors' {
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'Does not derive the log name from a filename setting the configuration may not have' -Skip:($Name -like 'Application/*') {
        (Get-Content -Path $Path -Raw) | Should -Not -Match '\$InstallConfig\.filename\.Replace'
    }
}

Describe 'Template configuration <Name>' -ForEach $Configs {
    It 'Is valid JSON with a name and version' {
        $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $config.PSObject.Properties.Name | Should -Contain 'name'
        $config.PSObject.Properties.Name | Should -Contain 'version'
    }
}

Describe 'Template folder <Name>' -ForEach $Folders {
    It 'Contains the main installer and a configuration file' {
        Join-Path -Path $Path -ChildPath 'Intune-I-MainInstaller.ps1' | Should -Exist
        Join-Path -Path $Path -ChildPath 'config.installer.json' | Should -Exist
    }

    It 'Builds a package with the logging function and a detection script from the shared files' {
        $package = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $package -ItemType Directory
        InModuleScope tcs.intune.packaging -Parameters @{ Template = $Name; Package = $package } {
            Copy-APFTemplate -Template $Template -Destination $Package
        }
        Join-Path -Path $package -ChildPath 'Intune-I-MainInstaller.ps1' | Should -Exist
        (Get-FileHash -Path (Join-Path -Path $package -ChildPath 'Write-DeploymentLog.ps1')).Hash | Should -Be (Get-FileHash -Path (Join-Path -Path $TemplateRoot -ChildPath '_shared/Write-DeploymentLog.ps1')).Hash
        @(Get-ChildItem -Path $package -Filter 'Intune-D-*.ps1').Count | Should -Be 1
    }
}

Describe 'Shared template files' {
    It 'Keeps no byte-identical copies of a script in the template folders' {
        $scripts = Get-ChildItem -Path $TemplateRoot -Recurse -Filter '*.ps1'
        $duplicates = $scripts | Group-Object -Property { (Get-FileHash -Path $_.FullName).Hash } | Where-Object { $_.Count -gt 1 }
        $duplicates | ForEach-Object { $_.Group.FullName -join ', ' } | Should -BeNullOrEmpty
    }
}
