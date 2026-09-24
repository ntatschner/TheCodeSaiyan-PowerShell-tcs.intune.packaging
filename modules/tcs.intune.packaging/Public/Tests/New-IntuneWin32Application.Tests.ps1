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
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath '../../../../tests/TestHelpers/New-TestIntuneWin.ps1')
        $script:Stubs = Add-GraphCommandStub
        $script:Package = (New-TestIntuneWin -Path (Join-Path -Path $TestDrive -ChildPath 'MyApp.intunewin') -SetupFile 'setup.msi').FullName
        $script:Detection = @{ '@odata.type' = '#microsoft.graph.win32LobAppProductCodeRule'; ruleType = 'detection'; productCode = '{ABC}'; productVersionOperator = 'notConfigured'; productVersion = $null }
        $script:Common = @{
            Name                 = 'MyApp'
            Description          = 'My application'
            Publisher            = 'Contoso'
            InstallCommandLine   = 'msiexec /i "setup.msi" /qn'
            UninstallCommandLine = 'msiexec /x "setup.msi" /qn'
            Rules                = $script:Detection
            IntuneWinFilePath    = $script:Package
        }
    }

    AfterAll {
        foreach ($name in $script:Stubs) {
            Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
        }
    }

    BeforeEach {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { [PSCustomObject]@{ Account = 'admin@contoso.com'; TenantId = 't' } }
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ id = 'app-1'; displayName = 'MyApp' } } -ParameterFilter { $Method -eq 'POST' -and $Uri -eq 'v1.0/deviceAppManagement/mobileApps' }
        Mock -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent { '1' }
    }

    It 'Loads on every PowerShell edition and offers tab completion instead of a PowerShell 7-only ValidateSet class' {
        $parameter = (Get-Command -Name New-IntuneWin32Application).Parameters['ExistingPackage']
        @($parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }).Count | Should -Be 1
    }

    It 'Creates the win32LobApp with the documented properties and uploads the content' {
        $app = New-IntuneWin32Application @script:Common -Version '1.2.3' -Confirm:$false
        $app.id | Should -Be 'app-1'
        $app.committedContentVersion | Should -Be '1'
        Should -Invoke -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent -Times 1 -Exactly -ParameterFilter { $AppId -eq 'app-1' -and $IntuneWinPath -eq $script:Package }
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and $Uri -eq 'v1.0/deviceAppManagement/mobileApps' -and $ContentType -eq 'application/json' -and
            $body.'@odata.type' -eq '#microsoft.graph.win32LobApp' -and
            $body.displayName -eq 'MyApp' -and $body.publisher -eq 'Contoso' -and
            $body.installCommandLine -eq 'msiexec /i "setup.msi" /qn' -and
            $body.fileName -eq 'MyApp.intunewin' -and $body.setupFilePath -eq 'setup.msi' -and
            $body.applicableArchitectures -eq 'x64' -and
            $body.installExperience.runAsAccount -eq 'system' -and $body.installExperience.deviceRestartBehavior -eq 'basedOnReturnCode' -and
            @($body.rules).Count -eq 1 -and $body.rules[0].productCode -eq '{ABC}' -and
            (@($body.returnCodes | ForEach-Object { "$($_.returnCode):$($_.type)" }) -join ',') -eq '0:success,1707:success,3010:softReboot,1641:hardReboot,1618:retry' -and
            $body.notes -eq 'Version: 1.2.3' -and
            -not ($body.PSObject.Properties.Name -contains 'minimumSupportedWindowsRelease')
        }
    }

    It 'Adds the icon as mimeContent' {
        $icon = Join-Path -Path $TestDrive -ChildPath 'icon.png'
        [System.IO.File]::WriteAllBytes($icon, [byte[]](1, 2, 3))
        $null = New-IntuneWin32Application @script:Common -IconFilePath $icon -Confirm:$false
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and $body.largeIcon.type -eq 'image/png' -and $body.largeIcon.value -eq 'AQID'
        }
    }

    It 'Requires a detection rule' {
        $requirement = @{ '@odata.type' = '#microsoft.graph.win32LobAppRegistryRule'; ruleType = 'requirement' }
        { New-IntuneWin32Application @script:Common -Rules $requirement -Confirm:$false } | Should -Throw '*detection rule*'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 0 -Exactly
    }

    It 'Creates nothing with -WhatIf' {
        $null = New-IntuneWin32Application @script:Common -WhatIf
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 0 -Exactly
        Should -Invoke -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent -Times 0 -Exactly
    }

    It 'Reports the created app when the upload fails' {
        Mock -ModuleName tcs.intune.packaging Publish-IntuneWin32AppContent { throw 'upload broke' }
        { New-IntuneWin32Application @script:Common -Confirm:$false } | Should -Throw '*app-1*upload broke*'
    }

    It 'Throws a clear error when not connected to Microsoft Graph' {
        Mock -ModuleName tcs.intune.packaging Get-MgContext { }
        { New-IntuneWin32Application @script:Common -Confirm:$false } | Should -Throw '*Connect-MgGraph*'
    }

    It 'Copies the settings of an existing app and applies the parameters on top' {
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest {
            [PSCustomObject]@{
                '@odata.type'        = '#microsoft.graph.win32LobApp'
                displayName          = 'Old App'
                description          = 'Old description'
                publisher            = 'Old publisher'
                installCommandLine   = 'old-install.cmd'
                uninstallCommandLine = 'old-uninstall.cmd'
                rules                = @([PSCustomObject]@{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemRule'; ruleType = 'detection'; path = 'C:\App'; fileOrFolderName = 'app.exe'; operationType = 'exists' })
                returnCodes          = @([PSCustomObject]@{ returnCode = 0; type = 'success' })
            }
        } -ParameterFilter { $Method -eq 'GET' -and $Uri -eq 'v1.0/deviceAppManagement/mobileApps/old-id' }
        $null = New-IntuneWin32Application -ExistingPackage 'Old App | old-id' -Name 'New App' -IntuneWinFilePath $script:Package -Confirm:$false
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Method -eq 'POST' -and $body.displayName -eq 'New App' -and $body.description -eq 'Old description' -and
            $body.installCommandLine -eq 'old-install.cmd' -and $body.rules[0].fileOrFolderName -eq 'app.exe' -and @($body.returnCodes).Count -eq 1
        }
    }
}
