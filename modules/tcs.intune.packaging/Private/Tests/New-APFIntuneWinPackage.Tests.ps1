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
Describe 'New-APFIntuneWinPackage' {
    BeforeEach {
        $Tool = Join-Path -Path $TestDrive -ChildPath 'IntuneWinAppUtil.exe'
        Set-Content -Path $Tool -Value 'x'
        $Source = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Source -ItemType Directory
        $Setup = Join-Path -Path $Source -ChildPath 'Intune-I-MainInstaller.ps1'
        Set-Content -Path $Setup -Value 'x'
        $Output = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Output -ItemType Directory
        Mock -ModuleName tcs.intune.packaging Get-IntuneWinAppUtilPath { $Tool }
    }

    It 'Runs the tool and renames the output to the package name' {
        Mock -ModuleName tcs.intune.packaging Invoke-Executable {
            Set-Content -Path (Join-Path -Path $Output -ChildPath 'Intune-I-MainInstaller.intunewin') -Value 'pkg'
            [PSCustomObject]@{ ExitCode = 0 }
        }
        $package = InModuleScope tcs.intune.packaging -Parameters @{ Source = $Source; Setup = $Setup; Output = $Output } {
            New-APFIntuneWinPackage -SourceFolder $Source -SetupFile $Setup -OutputFolder $Output -PackageName 'MyPkg' -Confirm:$false
        }
        $package.Name | Should -Be 'MyPkg.intunewin'
        Join-Path -Path $Output -ChildPath 'Intune-I-MainInstaller.intunewin' | Should -Not -Exist
    }

    It 'Throws when the tool does not create a package' {
        Mock -ModuleName tcs.intune.packaging Invoke-Executable { [PSCustomObject]@{ ExitCode = 1; StandardError = 'boom' } }
        {
            InModuleScope tcs.intune.packaging -Parameters @{ Source = $Source; Setup = $Setup; Output = $Output } {
                New-APFIntuneWinPackage -SourceFolder $Source -SetupFile $Setup -OutputFolder $Output -Confirm:$false
            }
        } | Should -Throw '*exit code 1*'
    }
}
