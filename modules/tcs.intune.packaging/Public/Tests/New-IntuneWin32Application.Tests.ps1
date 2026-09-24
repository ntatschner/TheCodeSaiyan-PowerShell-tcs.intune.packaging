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
Describe 'New-IntuneWin32Application' {
    It 'Loads on every PowerShell edition and offers tab completion instead of a PowerShell 7-only ValidateSet class' {
        $parameter = (Get-Command -Name New-IntuneWin32Application).Parameters['ExistingPackage']
        @($parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }).Count | Should -Be 1
    }

    It 'Throws a clear error when the Microsoft Graph module is missing' {
        Mock -ModuleName tcs.intune.packaging Get-Command { } -ParameterFilter { $Name -eq 'Get-MgDeviceAppManagementMobileApp' }
        $package = Join-Path -Path $TestDrive -ChildPath 'app.intunewin'
        Set-Content -Path $package -Value 'x'
        { New-IntuneWin32Application -Name 'App' -Description 'D' -Version '1.0' -Publisher 'P' -Owner 'O' -Developer 'Dv' -IntuneWinFilePath $package } | Should -Throw '*Microsoft.Graph*'
    }

    Context 'With Microsoft Graph available' {
        BeforeAll {
            $script:DefinedStub = $false
            if (-not (Get-Command -Name Get-MgDeviceAppManagementMobileApp -ErrorAction SilentlyContinue)) {
                function global:Get-MgDeviceAppManagementMobileApp { param($MobileAppId, $ExpandProperty, $Filter, $Property, [switch]$All) }
                $script:DefinedStub = $true
            }
        }

        AfterAll {
            if ($script:DefinedStub) {
                Remove-Item -Path Function:\global:Get-MgDeviceAppManagementMobileApp -ErrorAction SilentlyContinue
            }
        }

        It 'Reports that creating the application is not implemented' {
            $package = Join-Path -Path $TestDrive -ChildPath 'app.intunewin'
            Set-Content -Path $package -Value 'x'
            New-IntuneWin32Application -Name 'App' -Description 'D' -Version '1.0' -Publisher 'P' -Owner 'O' -Developer 'Dv' -IntuneWinFilePath $package -ErrorVariable appError -ErrorAction SilentlyContinue
            "$appError" | Should -Match 'not implemented'
        }
    }
}
