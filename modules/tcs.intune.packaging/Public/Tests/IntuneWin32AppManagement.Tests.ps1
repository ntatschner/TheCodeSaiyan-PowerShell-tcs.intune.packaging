BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
    . (Join-Path -Path $PSScriptRoot -ChildPath '../../../../tests/TestHelpers/New-TestIntuneWin.ps1')
    $script:Stubs = Add-GraphCommandStub
}

AfterAll {
    foreach ($name in $script:Stubs) {
        Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
    }
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}

Describe 'Win32 app management commands' {
    BeforeEach {
        $script:Calls = [System.Collections.Generic.List[object]]::new()
        $script:App = [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'app-1'; displayName = 'MyApp'; notes = 'Packaged by IT' }
        Mock -ModuleName tcs.intune.packaging Get-MgContext { [PSCustomObject]@{ Account = 'a'; TenantId = 't' } }
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest {
            $script:Calls.Add([PSCustomObject]@{ Method = $Method; Uri = $Uri; Body = $Body })
            if ($Method -ne 'GET') {
                return
            }
            switch -Wildcard ($Uri) {
                '*mobileApps[?]*' { [PSCustomObject]@{ value = @($script:App, [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.winGetApp'; id = 'store'; displayName = 'MyApp' }) } }
                '*/relationships' { [PSCustomObject]@{ value = @() } }
                default { $script:App }
            }
        }
    }

    Context 'Get-IntuneWin32App' {
        It 'Gets an app by ID' {
            (Get-IntuneWin32App -Id 'app-1').id | Should -Be 'app-1'
            $script:Calls[0].Uri | Should -Be 'v1.0/deviceAppManagement/mobileApps/app-1'
        }

        It 'Throws for an app that is not a Win32 app' {
            $script:App = [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.winGetApp'; id = 'store' }
            { Get-IntuneWin32App -Id 'store' } | Should -Throw '*not a Win32 app*'
        }

        It 'Gets only the Win32 apps with the display name' {
            $apps = @(Get-IntuneWin32App -Name "O'Brien")
            $apps.Count | Should -Be 1
            $apps[0].id | Should -Be 'app-1'
            $script:Calls[0].Uri | Should -Be "v1.0/deviceAppManagement/mobileApps?`$filter=$([System.Uri]::EscapeDataString("displayName eq 'O''Brien'"))"
        }

        It 'Lists all Win32 apps and follows the next link' {
            Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest {
                $script:Calls.Add([PSCustomObject]@{ Method = $Method; Uri = $Uri })
                if ($Uri -like '*page2*') {
                    [PSCustomObject]@{ value = @([PSCustomObject]@{ id = 'b' }) }
                }
                else {
                    [PSCustomObject]@{ value = @([PSCustomObject]@{ id = 'a' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/page2' }
                }
            }
            (Get-IntuneWin32App).id | Should -Be @('a', 'b')
            $script:Calls[0].Uri | Should -BeLike "*isof*win32LobApp*"
        }

        It 'Throws when not connected to Microsoft Graph' {
            Mock -ModuleName tcs.intune.packaging Get-MgContext { }
            { Get-IntuneWin32App -Id 'app-1' } | Should -Throw '*Connect-MgGraph*'
        }
    }

    Context 'Set-IntuneWin32App' {
        It 'Sends only the given properties' {
            Set-IntuneWin32App -Id 'app-1' -InstallCommandLine 'setup.exe /S' -Publisher 'Contoso' -Confirm:$false
            $patch = $script:Calls | Where-Object Method -EQ 'PATCH'
            $patch.Uri | Should -Be 'v1.0/deviceAppManagement/mobileApps/app-1'
            $body = $patch.Body | ConvertFrom-Json
            @($body.PSObject.Properties.Name | Sort-Object) | Should -Be @('@odata.type', 'installCommandLine', 'publisher')
            $body.installCommandLine | Should -Be 'setup.exe /S'
        }

        It 'Appends the version to the current notes' {
            Set-IntuneWin32App -Id 'app-1' -Version '2.0.1' -Confirm:$false
            $body = ($script:Calls | Where-Object Method -EQ 'PATCH').Body | ConvertFrom-Json
            $body.notes | Should -Be "Packaged by IT`nVersion: 2.0.1"
        }

        It 'Updates the app from the New-IntuneApplication JSON file' {
            $json = Join-Path -Path $TestDrive -ChildPath 'app.json'
            @{ ApplicationParameters = @{ ApplicationName = 'MyApp'; Publisher = 'Contoso'; InstallCommand = 'a'; UninstallCommand = 'b'; InstallFor = 'User'; DetectionRuleConfig = @{ '@odata.type' = '#microsoft.graph.win32LobAppProductCodeRule'; ruleType = 'detection'; productCode = '{X}' } } } | ConvertTo-Json -Depth 5 | Set-Content -Path $json
            Set-IntuneWin32App -Id 'app-1' -JsonPath $json -Confirm:$false
            $body = ($script:Calls | Where-Object Method -EQ 'PATCH').Body | ConvertFrom-Json
            $body.displayName | Should -Be 'MyApp'
            $body.installExperience.runAsAccount | Should -Be 'user'
            @($body.rules)[0].productCode | Should -Be '{X}'
        }

        It 'Rejects rules without a detection rule' {
            $requirement = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemRule'; ruleType = 'requirement' }
            { Set-IntuneWin32App -Id 'app-1' -Rules $requirement -Confirm:$false } | Should -Throw '*detection rule*'
        }

        It 'Throws when there is nothing to update' {
            { Set-IntuneWin32App -Id 'app-1' -Confirm:$false } | Should -Throw '*Nothing to update*'
        }

        It 'Returns the app with -PassThru and sends nothing with -WhatIf' {
            (Set-IntuneWin32App -Id 'app-1' -Notes 'x' -PassThru -Confirm:$false).id | Should -Be 'app-1'
            $script:Calls.Clear()
            Set-IntuneWin32App -Id 'app-1' -Notes 'x' -WhatIf
            @($script:Calls | Where-Object Method -EQ 'PATCH').Count | Should -Be 0
        }
    }

    Context 'Remove-IntuneWin32App' {
        It 'Deletes a Win32 app' {
            Remove-IntuneWin32App -Id 'app-1' -Confirm:$false
            ($script:Calls | Where-Object Method -EQ 'DELETE').Uri | Should -Be 'v1.0/deviceAppManagement/mobileApps/app-1'
        }

        It 'Deletes nothing with -WhatIf' {
            Remove-IntuneWin32App -Id 'app-1' -WhatIf
            @($script:Calls | Where-Object Method -EQ 'DELETE').Count | Should -Be 0
        }

        It 'Does not delete an app that is not a Win32 app' {
            $script:App = [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.winGetApp'; id = 'store' }
            Remove-IntuneWin32App -Id 'store' -Confirm:$false -ErrorVariable removeError -ErrorAction SilentlyContinue
            "$removeError" | Should -Match 'not a Win32 app'
            @($script:Calls | Where-Object Method -EQ 'DELETE').Count | Should -Be 0
        }

        It 'Accepts apps from the pipeline' {
            [PSCustomObject]@{ id = 'app-1' } | Remove-IntuneWin32App -Confirm:$false
            @($script:Calls | Where-Object Method -EQ 'DELETE').Count | Should -Be 1
        }
    }

    Context 'Supersedence and dependencies' {
        It 'Adds a supersedence relationship with Add-IntuneWin32AppSupersedence' {
            Add-IntuneWin32AppSupersedence -Id 'app-1' -SupersededAppId 'old-1' -SupersedenceType replace -Confirm:$false
            $post = $script:Calls | Where-Object Method -EQ 'POST'
            $post.Uri | Should -Be 'beta/deviceAppManagement/mobileApps/app-1/updateRelationships'
            $relationship = @(($post.Body | ConvertFrom-Json).relationships)[0]
            $relationship.'@odata.type' | Should -Be '#microsoft.graph.mobileAppSupersedence'
            $relationship.targetId | Should -Be 'old-1'
            $relationship.supersedenceType | Should -Be 'replace'
        }

        It 'Adds dependency relationships with Add-IntuneWin32AppDependency' {
            Add-IntuneWin32AppDependency -Id 'app-1' -DependsOnAppId 'dep-1', 'dep-2' -Confirm:$false
            $relationships = @((($script:Calls | Where-Object Method -EQ 'POST').Body | ConvertFrom-Json).relationships)
            $relationships.Count | Should -Be 2
            $relationships[0].'@odata.type' | Should -Be '#microsoft.graph.mobileAppDependency'
            $relationships.dependencyType | Should -Be @('autoInstall', 'autoInstall')
        }

        It 'Rejects an app that supersedes or depends on itself' {
            { Add-IntuneWin32AppSupersedence -Id 'app-1' -SupersededAppId 'app-1' -Confirm:$false } | Should -Throw '*itself*'
            { Add-IntuneWin32AppDependency -Id 'app-1' -DependsOnAppId 'app-1' -Confirm:$false } | Should -Throw '*itself*'
        }

        It 'Sends nothing with -WhatIf' {
            Add-IntuneWin32AppSupersedence -Id 'app-1' -SupersededAppId 'old-1' -WhatIf
            Add-IntuneWin32AppDependency -Id 'app-1' -DependsOnAppId 'dep-1' -WhatIf
            @($script:Calls | Where-Object Method -EQ 'POST').Count | Should -Be 0
        }
    }
}

Describe 'Get-IntuneWinPackageInfo' {
    It 'Returns the package metadata without the encryption keys' {
        $package = New-TestIntuneWin -Path (Join-Path -Path $TestDrive -ChildPath 'info.intunewin') -ContentSize 3000 -SetupFile 'install.msi'
        $info = $package | Get-IntuneWinPackageInfo
        $info.Path | Should -Be $package.FullName
        $info.SetupFile | Should -Be 'install.msi'
        $info.UnencryptedContentSize | Should -Be 2952
        $info.EncryptedContentSize | Should -Be 3000
        $info.ToolVersion | Should -Be '1.8.6'
        $info.PSObject.Properties.Name | Should -Not -Contain 'EncryptionInfo'
    }

    It 'Throws for a file that is not a .intunewin package' {
        $file = Join-Path -Path $TestDrive -ChildPath 'plain.txt'
        Set-Content -Path $file -Value 'x'
        { Get-IntuneWinPackageInfo -Path $file } | Should -Throw
    }
}
