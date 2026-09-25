BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
    # New-PackageJSON is deprecated; keep the expected warning out of the test output
    $PSDefaultParameterValues['New-PackageJSON:WarningAction'] = 'SilentlyContinue'
}

AfterAll {
    $PSDefaultParameterValues.Remove('New-PackageJSON:WarningAction')
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}

Describe 'New-PackageJSON' {
    BeforeEach {
        $Source = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path (Join-Path -Path $Source -ChildPath 'sub') -ItemType Directory -Force
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'setup.exe') -Value 'x'
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'sub/readme.txt') -Value 'x'
    }

    It 'Writes the package metadata to the source directory' {
        $file = New-PackageJSON -PackageName 'MyApp' -Version '1.2.3' -Description 'Desc' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe'
        $file.Name | Should -Be 'package-MyApp-v1.2.3.json'
        $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $json.PackageName | Should -Be 'MyApp'
        $json.Version | Should -Be '1.2.3'
        $json.MainInstaller | Should -Be 'setup.exe'
        ($json.AllFiles -split ',') | Should -Contain 'setup.exe'
        ($json.AllFiles -split ',') | Should -Contain 'readme.txt'
    }

    It 'Does not list its own metadata file when run again' {
        $null = New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'Desc' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe'
        $file = New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'Desc' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe'
        (Get-Content -Path $file.FullName -Raw | ConvertFrom-Json).AllFiles | Should -Not -Match 'package-MyApp'
    }

    It 'Writes nothing with -WhatIf' {
        New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'Desc' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe' -WhatIf
        Join-Path -Path $Source -ChildPath 'package-MyApp-v1.0.json' | Should -Not -Exist
    }

    It 'Writes a deprecation warning' {
        $null = New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'D' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe' -WarningVariable deprecation -WarningAction SilentlyContinue
        "$deprecation" | Should -Match 'deprecated'
    }

    It 'Rejects a source directory that does not exist' {
        { New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'D' -Author 'IT' -SourceDirectory (Join-Path -Path $TestDrive -ChildPath 'nope') -MainInstaller 'setup.exe' } | Should -Throw
    }
}

Describe 'New-PackageJSON telemetry' {
    BeforeEach {
        Mock -ModuleName tcs.intune.packaging Invoke-TelemetryCollection { }
        $Source = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Source -ItemType Directory -Force
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'setup.exe') -Value 'x'
    }

    It 'Reports Start and a successful End and returns only the file' {
        $output = @(New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'D' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe')
        $output.Count | Should -Be 1
        $output[0] | Should -BeOfType ([System.IO.FileInfo])
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'Start' -and $CommandName -eq 'New-PackageJSON' }
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
    }

    It 'Reports a failed End when the file cannot be written and still throws' {
        Mock -ModuleName tcs.intune.packaging Set-Content { throw 'disk full' }
        { New-PackageJSON -PackageName 'MyApp' -Version '1.0' -Description 'D' -Author 'IT' -SourceDirectory $Source -MainInstaller 'setup.exe' } | Should -Throw '*disk full*'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and $Failed -eq $true }
    }
}
