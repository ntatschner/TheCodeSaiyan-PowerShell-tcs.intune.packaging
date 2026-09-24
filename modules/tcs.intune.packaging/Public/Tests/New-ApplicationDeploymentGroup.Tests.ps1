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
Describe 'New-ApplicationDeploymentGroup' {
    Context 'Group names' {
        It 'Returns the four deployment groups for each application' {
            $groups = New-ApplicationDeploymentGroup -ApplicationName 'microsoft 365 apps', 'Google Chrome'
            $groups.Count | Should -Be 8
            $groups.GroupName | Should -Contain 'Intune-AG-Microsoft365Apps-Available'
            $groups.GroupName | Should -Contain 'Intune-AG-Microsoft365Apps-Required'
            $groups.GroupName | Should -Contain 'Intune-App-GoogleChrome-Test'
            $groups.GroupName | Should -Contain 'Intune-App-GoogleChrome-Phase1'
        }

        It 'Is also available as New-ApplicationDeploymentGroups' {
            (Get-Alias -Name New-ApplicationDeploymentGroups).ResolvedCommandName | Should -Be 'New-ApplicationDeploymentGroup'
        }

        It 'Exports the list to a CSV file' {
            $null = New-ApplicationDeploymentGroup -ApplicationName 'App' -CreateFile -Destination $TestDrive
            $rows = Import-Csv -Path (Join-Path -Path $TestDrive -ChildPath 'Application-Groups.csv')
            $rows.Count | Should -Be 4
            $rows[0].PSObject.Properties.Name | Should -Be @('Name', 'GroupName', 'GroupDescription')
        }
    }

    Context 'Creating groups' {
        BeforeAll {
            # The Microsoft.Entra and Microsoft.Graph commands are not installed in CI; define stand-ins to mock
            $script:Stubs = @()
            foreach ($name in 'Get-EntraGroup', 'New-EntraGroup', 'Add-EntraGroupMember', 'Add-MgDirectoryAdministrativeUnitMember') {
                if (-not (Get-Command -Name $name -ErrorAction SilentlyContinue)) {
                    Set-Item -Path "Function:\global:$name" -Value { param($Filter, $DisplayName, $MailEnabled, $SecurityEnabled, $MailNickname, $Description, $GroupId, $MemberId, $AdministrativeUnitId, $DirectoryObjectId) }
                    $script:Stubs += $name
                }
            }
        }

        AfterAll {
            foreach ($name in $script:Stubs) {
                Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
            }
        }

        BeforeEach {
            Mock -ModuleName tcs.intune.packaging Get-EntraGroup { }
            Mock -ModuleName tcs.intune.packaging New-EntraGroup { [PSCustomObject]@{ Id = "id-$DisplayName"; DisplayName = $DisplayName } }
            Mock -ModuleName tcs.intune.packaging Add-EntraGroupMember { }
            Mock -ModuleName tcs.intune.packaging Add-MgDirectoryAdministrativeUnitMember { }
        }

        It 'Creates the missing groups and adds members to the matching group only' {
            $null = New-ApplicationDeploymentGroup -ApplicationName 'App' -CreateGroups -TestMembers 'user-1' -Confirm:$false
            Should -Invoke -ModuleName tcs.intune.packaging New-EntraGroup -Times 4 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Add-EntraGroupMember -Times 1 -Exactly -ParameterFilter {
                $GroupId -eq 'id-Intune-App-App-Test' -and $MemberId -eq 'user-1'
            }
        }

        It 'Skips groups that already exist' {
            Mock -ModuleName tcs.intune.packaging Get-EntraGroup { [PSCustomObject]@{ Id = 'existing' } } -ParameterFilter { $Filter -like "*-Available'" }
            $null = New-ApplicationDeploymentGroup -ApplicationName 'App' -CreateGroups -Confirm:$false
            Should -Invoke -ModuleName tcs.intune.packaging New-EntraGroup -Times 3 -Exactly
        }

        It 'Adds new groups to the administrative unit' {
            $null = New-ApplicationDeploymentGroup -ApplicationName 'App' -CreateGroups -AdminUnitId 'au-1' -Confirm:$false
            Should -Invoke -ModuleName tcs.intune.packaging Add-MgDirectoryAdministrativeUnitMember -Times 4 -Exactly -ParameterFilter { $AdministrativeUnitId -eq 'au-1' }
        }

        It 'Creates nothing with -WhatIf' {
            $null = New-ApplicationDeploymentGroup -ApplicationName 'App' -CreateGroups -WhatIf
            Should -Invoke -ModuleName tcs.intune.packaging New-EntraGroup -Times 0 -Exactly
        }
    }
}
