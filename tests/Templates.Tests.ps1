BeforeDiscovery {
    $TemplateRoot = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'modules/tcs.intune.packaging/Public/Templates'
    $Scripts = @(Get-ChildItem -Path $TemplateRoot -Recurse -Filter '*.ps1' | ForEach-Object { @{ Name = "$($_.Directory.Name)/$($_.Name)"; Path = $_.FullName } })
    $Configs = @(Get-ChildItem -Path $TemplateRoot -Recurse -Filter 'config.installer.json' | ForEach-Object { @{ Name = $_.Directory.Name; Path = $_.FullName } })
    $Folders = @(Get-ChildItem -Path $TemplateRoot -Directory | ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } })
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
    It 'Contains the main installer, the logging function and a configuration file' {
        Join-Path -Path $Path -ChildPath 'Intune-I-MainInstaller.ps1' | Should -Exist
        Join-Path -Path $Path -ChildPath 'Write-DeploymentLog.ps1' | Should -Exist
        Join-Path -Path $Path -ChildPath 'config.installer.json' | Should -Exist
    }
}
