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
Describe 'Publish-IntuneAppPackage' {
    BeforeAll {
        $script:Json = Join-Path -Path $TestDrive -ChildPath 'app.json'
        @{ ApplicationParameters = @{ ApplicationName = "O'Brien App" } } | ConvertTo-Json | Set-Content -Path $script:Json
        $script:Package = Join-Path -Path $TestDrive -ChildPath 'app.intunewin'
        Set-Content -Path $script:Package -Value 'x'
        $script:Stubs = @()
        foreach ($name in 'Get-MgContext', 'Get-MgDeviceAppManagementMobileApp') {
            if (-not (Get-Command -Name $name -ErrorAction SilentlyContinue)) {
                Set-Item -Path "Function:\global:$name" -Value { param($Filter) }
                $script:Stubs += $name
            }
        }
    }

    AfterAll {
        foreach ($name in $script:Stubs) {
            Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
        }
    }

    It 'Throws when not connected to Microsoft Graph' {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { }
        { Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package } | Should -Throw '*Connect-MgGraph*'
    }

    It 'Throws when the application exists and -Force is not used' {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { [PSCustomObject]@{ Account = 'a'; TenantId = 't' } }
        Mock -ModuleName tcs.intune.packaging Get-MgDeviceAppManagementMobileApp { [PSCustomObject]@{ Id = '1' } }
        { Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails } | Should -Throw '*already exists*'
        Should -Invoke -ModuleName tcs.intune.packaging Get-MgDeviceAppManagementMobileApp -ParameterFilter { $Filter -eq "displayName eq 'O''Brien App'" }
    }

    It 'Reports that uploading is not implemented after the checks pass' {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { [PSCustomObject]@{ Account = 'a'; TenantId = 't' } }
        Mock -ModuleName tcs.intune.packaging Get-MgDeviceAppManagementMobileApp { }
        Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails -ErrorVariable publishError -ErrorAction SilentlyContinue
        "$publishError" | Should -Match 'not implemented'
    }
}
