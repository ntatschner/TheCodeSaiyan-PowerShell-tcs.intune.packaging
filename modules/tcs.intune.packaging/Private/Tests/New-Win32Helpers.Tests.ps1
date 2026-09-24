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
Describe 'Win32 application helpers' {
    It 'New-Win32ApplicationInfo returns the bound values without common parameters' {
        InModuleScope tcs.intune.packaging {
            $info = New-Win32ApplicationInfo -displayName 'App' -description 'D' -publisher 'P' -Verbose 4>$null
            $info.displayName | Should -Be 'App'
            $info.isFeatured | Should -BeFalse
            $info.Keys | Should -Not -Contain 'Verbose'
        }
    }

    It 'New-Win32InstallExperience accepts the user account' {
        InModuleScope tcs.intune.packaging {
            $experience = New-Win32InstallExperience -runAsAccount user -maxRunTimeInMinutes 30
            $experience.runAsAccount | Should -Be 'user'
            $experience.maxRunTimeInMinutes | Should -Be '30'
            (New-Win32InstallExperience).ContainsKey('maxRunTimeInMinutes') | Should -BeFalse
        }
    }

    It 'New-Win32Installation returns the command lines' {
        InModuleScope tcs.intune.packaging {
            $installation = New-Win32Installation -installCommandLine 'setup.exe /S' -uninstallCommandLine 'setup.exe /U'
            $installation.installCommandLine | Should -Be 'setup.exe /S'
            $installation.allowAvailableUninstall | Should -BeFalse
        }
    }

    It 'New-Win32Requirement adds the default architecture' {
        InModuleScope tcs.intune.packaging {
            $requirement = New-Win32Requirement -minimumSupportedWindowsRelease Windows10_1909 -Verbose 4>$null
            $requirement.applicableArchitectures | Should -Be 'x86,x64'
            $requirement.Keys | Should -Not -Contain 'Verbose'
        }
    }

    It 'New-Win32ReturnCode returns the code and type' {
        InModuleScope tcs.intune.packaging {
            $code = New-Win32ReturnCode -ReturnCode 3010 -ReturnMessage softReboot
            $code.returnCode | Should -Be '3010'
            $code.type | Should -Be 'softReboot'
        }
    }
}
