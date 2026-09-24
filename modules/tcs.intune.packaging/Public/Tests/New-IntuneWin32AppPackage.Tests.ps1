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
Describe 'New-IntuneWin32AppPackage' {
    BeforeEach {
        $Source = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Source -ItemType Directory
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'setup.exe') -Value 'x'
        $Output = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Output -ItemType Directory
        $Tool = Join-Path -Path $TestDrive -ChildPath 'IntuneWinAppUtil.exe'
        Set-Content -Path $Tool -Value 'x'
        Mock -ModuleName tcs.intune.packaging Invoke-Executable {
            Set-Content -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -Value 'pkg'
            [PSCustomObject]@{ ExitCode = 0; StandardOutput = $null; StandardError = $null }
        }
    }

    It 'Returns the package details without the optional IntuneWin32App module' {
        $result = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool
        $result.Path | Should -Be (Join-Path -Path $Output -ChildPath 'setup.intunewin')
        $result.FileName | Should -Be 'setup.intunewin'
        $result.SetupFile | Should -Be 'setup.exe'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly -ParameterFilter { $FilePath -eq $Tool -and $Arguments -like '*-q' }
    }

    It 'Does not overwrite an existing package without -Force' {
        Set-Content -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -Value 'old'
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -WarningAction SilentlyContinue
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 0 -Exactly
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -Force
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly
    }

    It 'Warns when the setup file is not in the source folder' {
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'missing.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -WarningVariable pkgWarning -WarningAction SilentlyContinue
        "$pkgWarning" | Should -Match 'missing.exe'
    }

    It 'Creates nothing with -WhatIf' {
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -WhatIf
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 0 -Exactly
    }
}
