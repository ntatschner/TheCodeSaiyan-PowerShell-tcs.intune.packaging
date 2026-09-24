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
        . (Join-Path -Path $PSScriptRoot -ChildPath '../../../../tests/TestHelpers/New-TestIntuneWin.ps1')
        $script:Stubs = Add-GraphCommandStub
        $script:Package = (New-TestIntuneWin -Path (Join-Path -Path $TestDrive -ChildPath 'app.intunewin')).FullName
        $script:Json = Join-Path -Path $TestDrive -ChildPath 'app.json'
        @{
            ApplicationParameters = @{
                ApplicationName     = "O'Brien App"
                Description         = 'Desc'
                Publisher           = 'Contoso'
                Version             = '2.1'
                InstallCommand      = 'setup.exe /S'
                UninstallCommand    = 'setup.exe /U'
                InstallFor          = 'System'
                RestartBehavior     = 'suppress'
                DetectionRuleConfig = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemRule'; ruleType = 'detection'; path = 'C:\App'; fileOrFolderName = 'app.exe'; operationType = 'exists'; operator = 'notConfigured'; check32BitOn64System = $false }
            }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $script:Json
    }

    AfterAll {
        foreach ($name in $script:Stubs) {
            Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
        }
    }

    BeforeEach {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { [PSCustomObject]@{ Account = 'a'; TenantId = 't' } }
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ value = @() } }
        Mock -ModuleName tcs.intune.packaging New-IntuneWin32Application { [PSCustomObject]@{ id = 'new-id' } }
        Mock -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent { '3' }
    }

    It 'Throws when not connected to Microsoft Graph' {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { }
        { Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package } | Should -Throw '*Connect-MgGraph*'
    }

    It 'Creates a new app from the JSON configuration' {
        $app = Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails
        $app.id | Should -Be 'new-id'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Uri -eq "v1.0/deviceAppManagement/mobileApps?`$filter=$([System.Uri]::EscapeDataString("displayName eq 'O''Brien App'"))"
        }
        Should -Invoke -ModuleName tcs.intune.packaging New-IntuneWin32Application -Times 1 -Exactly -ParameterFilter {
            $Name -eq "O'Brien App" -and $Publisher -eq 'Contoso' -and $InstallCommandLine -eq 'setup.exe /S' -and
            $UninstallCommandLine -eq 'setup.exe /U' -and $InstallExperienceRunAsAccount -eq 'system' -and
            $InstallExperienceDeviceRestartBehavior -eq 'suppress' -and $Version -eq [version]'2.1' -and
            $Rules.Count -eq 1 -and $Rules[0].fileOrFolderName -eq 'app.exe' -and $IntuneWinFilePath -eq $script:Package
        }
    }

    It 'Uses -Rules instead of the rules in the JSON file' {
        $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppProductCodeRule'; ruleType = 'detection'; productCode = '{X}' }
        $null = Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails -Rules $rule
        Should -Invoke -ModuleName tcs.intune.packaging New-IntuneWin32Application -Times 1 -Exactly -ParameterFilter { $Rules[0].productCode -eq '{X}' }
    }

    It 'Rejects rule configuration that was not made with New-IntuneWin32Rule' {
        $json = Join-Path -Path $TestDrive -ChildPath 'oldrules.json'
        @{ ApplicationParameters = @{ ApplicationName = 'App'; DetectionRuleConfig = @{ Type = 'File' } } } | ConvertTo-Json -Depth 5 | Set-Content -Path $json
        { Publish-IntuneAppPackage -IntuneAppJSONPath $json -IntuneWinPath $script:Package -NoTenantDetails } | Should -Throw '*New-IntuneWin32Rule*'
    }

    It 'Throws when the app exists and -Force is not used' {
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ value = @([PSCustomObject]@{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'existing'; displayName = "O'Brien App" }) } }
        { Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails } | Should -Throw '*already exists*'
        Should -Invoke -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent -Times 0 -Exactly
    }

    It 'Uploads a new content version to the existing app with -Force' {
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ value = @([PSCustomObject]@{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'existing'; displayName = "O'Brien App" }) } }
        $app = Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails -Force -Confirm:$false
        $app.id | Should -Be 'existing'
        $app.committedContentVersion | Should -Be '3'
        Should -Invoke -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent -Times 1 -Exactly -ParameterFilter { $AppId -eq 'existing' }
        Should -Invoke -ModuleName tcs.intune.packaging New-IntuneWin32Application -Times 0 -Exactly
    }

    It 'Uploads nothing with -WhatIf' {
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ value = @([PSCustomObject]@{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'existing' }) } }
        $null = Publish-IntuneAppPackage -IntuneAppJSONPath $script:Json -IntuneWinPath $script:Package -NoTenantDetails -Force -WhatIf
        Should -Invoke -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent -Times 0 -Exactly
    }
}
