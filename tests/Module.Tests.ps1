BeforeDiscovery {
    $RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $ModuleRoot = Join-Path -Path $RepoRoot -ChildPath 'modules/tcs.intune.packaging'
    # Only the top level of Public/ holds exported functions; Public/Templates holds installer scripts
    $PublicFunctions = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' -File | ForEach-Object BaseName | ForEach-Object { @{ Name = $_ } })
    $ExportedFunctions = @((Import-PowerShellDataFile -Path (Join-Path $ModuleRoot 'tcs.intune.packaging.psd1')).FunctionsToExport | ForEach-Object { @{ Name = $_ } })
}

BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $ModuleRoot = Join-Path -Path $RepoRoot -ChildPath 'modules/tcs.intune.packaging'
    $ManifestPath = Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1'
    Import-Module -Name $ManifestPath -Force -ErrorVariable importErrors
    $Module = Get-Module -Name tcs.intune.packaging
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}

Describe 'tcs.intune.packaging module' {
    It 'Has a valid manifest' {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Requires tcs.core 0.3.0 or later' {
        $required = (Import-PowerShellDataFile -Path $ManifestPath).RequiredModules | Where-Object { $_.ModuleName -eq 'tcs.core' }
        [version]$required.ModuleVersion | Should -BeGreaterOrEqual ([version]'0.3.0')
    }

    It 'Imports without errors' {
        $importErrors.Count | Should -Be 0
    }

    It 'Exports exactly the functions in Public/ and listed in the manifest' {
        $publicFiles = Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' -File | ForEach-Object BaseName | Sort-Object
        $manifestExports = (Import-PowerShellDataFile -Path $ManifestPath).FunctionsToExport | Sort-Object
        $manifestExports | Should -Be $publicFiles
        ($Module.ExportedFunctions.Keys | Sort-Object) | Should -Be $publicFiles
    }

    It 'Exports the compatibility aliases listed in the manifest' {
        $manifestAliases = (Import-PowerShellDataFile -Path $ManifestPath).AliasesToExport | Sort-Object
        ($Module.ExportedAliases.Keys | Sort-Object) | Should -Be $manifestAliases
    }

    It 'Does not load the installer templates or private helpers as module commands' {
        $Module.ExportedFunctions.Keys | Should -Not -Contain 'Write-DeploymentLog'
        $Module.ExportedFunctions.Keys | Should -Not -Contain 'New-IntuneAppJSON'
        & $Module { Get-Command -Name Write-DeploymentLog -ErrorAction SilentlyContinue } | Should -BeNullOrEmpty
    }

    It 'Does not write to the module folder when imported' {
        Join-Path -Path $ModuleRoot -ChildPath 'Config.psd1' | Should -Not -Exist
    }

    It 'Does not write to the pipeline when imported' {
        $shell = (Get-Process -Id $PID).Path
        $output = & $shell -NoProfile -NonInteractive -Command "`$env:TCS_CONFIG_ROOT='$($env:TCS_CONFIG_ROOT)'; `$env:TCS_SKIP_UPDATE_CHECK='1'; `$env:TCS_TELEMETRY_OPTOUT='1'; `$env:PSModulePath='$($env:PSModulePath)'; Import-Module '$ManifestPath' 6>`$null; 'done'"
        $output | Should -Be 'done'
    }
}

Describe 'Help for <Name>' -ForEach $PublicFunctions {
    BeforeAll {
        $help = Get-Help -Name $Name -Full
    }

    It 'Has a synopsis' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Synopsis | Should -Not -Match "^\s*$Name\s"
    }

    It 'Has a description' {
        ($help.Description | Out-String).Trim() | Should -Not -BeNullOrEmpty
    }

    It 'Has at least one example' {
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'Documents every parameter' {
        $common = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        $parameters = (Get-Command -Name $Name).Parameters.Keys | Where-Object { $_ -notin $common }
        foreach ($parameter in $parameters) {
            $parameterHelp = $help.Parameters.Parameter | Where-Object Name -EQ $parameter
            ($parameterHelp.Description | Out-String).Trim() | Should -Not -BeNullOrEmpty -Because "parameter '$parameter' should be documented"
        }
    }
}

Describe 'Telemetry for <Name>' -ForEach $ExportedFunctions {
    # Coverage guard: every exported command reports a Start and an End event through tcs.core.
    # No command is excluded.
    BeforeAll {
        $definition = (Get-Command -Name $Name -Module tcs.intune.packaging).Definition
    }

    It 'Reports a Start event' {
        $definition | Should -Match 'Invoke-TelemetryCollection\s[^\r\n]*-Stage\s+[''"]?Start\b'
    }

    It 'Reports an End event' {
        $definition | Should -Match 'Invoke-TelemetryCollection\s[^\r\n]*-Stage\s+[''"]?End\b'
    }

    It 'Reports a failed End event' {
        $definition | Should -Match 'Invoke-TelemetryCollection\s[^\r\n]*-Stage\s+[''"]?End[''"]?\s[^\r\n]*-Failed\s+\$true'
    }
}

Describe 'PSScriptAnalyzer' -Skip:(-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    It 'Reports no findings with the repository settings' {
        $settings = Join-Path -Path $RepoRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
        # Pester files are excluded: PSScriptAnalyzer cannot follow Pester's block scoping.
        # Files are analysed one at a time and retried once, because PSScriptAnalyzer can throw an
        # intermittent internal NullReferenceException; an error that persists fails the test.
        $files = Get-ChildItem -Path $ModuleRoot -Recurse -Include '*.ps1', '*.psm1', '*.psd1' | Where-Object { $_.Name -notlike '*.Tests.ps1' }
        $findings = foreach ($file in $files) {
            try {
                Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settings -ErrorAction Stop
            }
            catch {
                Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settings -ErrorAction Stop
            }
        }
        $findings | ForEach-Object { Write-Host "$($_.ScriptName):$($_.Line) $($_.RuleName) $($_.Message)" }
        @($findings).Count | Should -Be 0
    }
}
