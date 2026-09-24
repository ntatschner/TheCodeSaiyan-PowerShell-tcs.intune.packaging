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

Describe 'Add-IntuneWin32AppAssignment' {
    BeforeEach {
        $script:Posts = [System.Collections.Generic.List[object]]::new()
        $script:Gets = [System.Collections.Generic.List[string]]::new()
        $script:ExistingAssignments = @()
        $script:Groups = @([PSCustomObject]@{ id = 'group-1'; displayName = 'Intune-AG-App-Required' })
        $script:Filters = @(
            [PSCustomObject]@{ id = 'filter-1'; displayName = 'Corporate devices' }
            [PSCustomObject]@{ id = 'filter-2'; displayName = 'Other' }
        )
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest {
            if ($Method -eq 'POST') {
                $script:Posts.Add([PSCustomObject]@{ Uri = $Uri; Body = ($Body | ConvertFrom-Json) })
                return
            }
            $script:Gets.Add($Uri)
            switch -Wildcard ($Uri) {
                'v1.0/groups*' { [PSCustomObject]@{ value = $script:Groups } }
                'beta/deviceManagement/assignmentFilters*' { [PSCustomObject]@{ value = $script:Filters } }
                '*/assignments' { [PSCustomObject]@{ value = $script:ExistingAssignments } }
            }
        }
    }

    It 'Assigns to all devices as required with Win32 assignment settings' {
        InModuleScope tcs.intune.packaging { $null = Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType All-Devices }
        $script:Posts.Count | Should -Be 1
        $script:Posts[0].Uri | Should -Be 'beta/deviceAppManagement/mobileApps/app-1/assign'
        $assignment = @($script:Posts[0].Body.mobileAppAssignments)
        $assignment.Count | Should -Be 1
        $assignment[0].'@odata.type' | Should -Be '#microsoft.graph.mobileAppAssignment'
        $assignment[0].intent | Should -Be 'required'
        $assignment[0].target.'@odata.type' | Should -Be '#microsoft.graph.allDevicesAssignmentTarget'
        $assignment[0].settings.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppAssignmentSettings'
        @($script:Gets | Where-Object { $_ -like 'v1.0/groups*' }).Count | Should -Be 0
    }

    It 'Assigns to all users with the chosen intent' {
        InModuleScope tcs.intune.packaging { $null = Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType All-Users -Intent available }
        $assignment = @($script:Posts[0].Body.mobileAppAssignments)[0]
        $assignment.intent | Should -Be 'available'
        $assignment.target.'@odata.type' | Should -Be '#microsoft.graph.allLicensedUsersAssignmentTarget'
    }

    It 'Looks up a group by display name' {
        InModuleScope tcs.intune.packaging { $null = Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType Device-Group -AssignmentGroup "Intune-AG-App-Required" -Intent uninstall }
        $script:Gets | Where-Object { $_ -like 'v1.0/groups*' } | Should -Be "v1.0/groups?`$filter=$([System.Uri]::EscapeDataString("displayName eq 'Intune-AG-App-Required'"))&`$select=id,displayName"
        $assignment = @($script:Posts[0].Body.mobileAppAssignments)[0]
        $assignment.intent | Should -Be 'uninstall'
        $assignment.target.'@odata.type' | Should -Be '#microsoft.graph.groupAssignmentTarget'
        $assignment.target.groupId | Should -Be 'group-1'
    }

    It 'Uses a group ID without a lookup' {
        $groupId = [guid]::NewGuid().ToString()
        InModuleScope tcs.intune.packaging -Parameters @{ GroupId = $groupId } { $null = Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType User-Group -AssignmentGroup $GroupId }
        @($script:Gets | Where-Object { $_ -like 'v1.0/groups*' }).Count | Should -Be 0
        @($script:Posts[0].Body.mobileAppAssignments)[0].target.groupId | Should -Be $groupId
    }

    It 'Throws when <Count> groups have the display name' -ForEach @(@{ Count = 0 }, @{ Count = 2 }) {
        $script:Groups = @(1..$Count | Where-Object { $Count -gt 0 } | ForEach-Object { [PSCustomObject]@{ id = "g$_"; displayName = 'Dup' } })
        { InModuleScope tcs.intune.packaging { Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType User-Group -AssignmentGroup 'Dup' } } | Should -Throw "*Found $Count groups*"
        $script:Posts.Count | Should -Be 0
    }

    It 'Adds an assignment filter by name' {
        InModuleScope tcs.intune.packaging { $null = Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType All-Devices -FilterRuleType Exclude -FilterRule 'Corporate devices' }
        $target = @($script:Posts[0].Body.mobileAppAssignments)[0].target
        $target.deviceAndAppManagementAssignmentFilterId | Should -Be 'filter-1'
        $target.deviceAndAppManagementAssignmentFilterType | Should -Be 'exclude'
    }

    It 'Keeps other assignments and replaces one to the same target' {
        $script:ExistingAssignments = @(
            [PSCustomObject]@{ id = 'a1'; intent = 'available'; target = [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = 'group-1' }; settings = $null }
            [PSCustomObject]@{ id = 'a2'; intent = 'required'; target = [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = 'other'; deviceAndAppManagementAssignmentFilterId = 'f9'; deviceAndAppManagementAssignmentFilterType = 'include' }; settings = $null }
        )
        InModuleScope tcs.intune.packaging { $null = Add-IntuneWin32AppAssignment -AppId 'app-1' -AssignmentType User-Group -AssignmentGroup 'Intune-AG-App-Required' }
        $assignments = @($script:Posts[0].Body.mobileAppAssignments)
        $assignments.Count | Should -Be 2
        $kept = $assignments | Where-Object { $_.target.groupId -eq 'other' }
        $kept.intent | Should -Be 'required'
        $kept.target.deviceAndAppManagementAssignmentFilterId | Should -Be 'f9'
        ($assignments | Where-Object { $_.target.groupId -eq 'group-1' }).intent | Should -Be 'required'
        $script:Gets | Should -Contain 'beta/deviceAppManagement/mobileApps/app-1/assignments'
    }

    It 'Rejects <Case>' -ForEach @(
        @{ Case = 'a group assignment without a group'; Arguments = @{ AssignmentType = 'User-Group' }; Message = '*needs AssignmentGroup*' }
        @{ Case = 'a group for all devices'; Arguments = @{ AssignmentType = 'All-Devices'; AssignmentGroup = 'x' }; Message = '*does not use AssignmentGroup*' }
        @{ Case = 'a filter without a filter type'; Arguments = @{ AssignmentType = 'All-Devices'; FilterRule = 'x' }; Message = '*used together*' }
    ) {
        { InModuleScope tcs.intune.packaging -Parameters @{ Arguments = $Arguments } { Add-IntuneWin32AppAssignment -AppId 'app-1' @Arguments } } | Should -Throw $Message
        $script:Posts.Count | Should -Be 0
    }
}

Describe 'Set-IntuneAppRelationship' {
    BeforeEach {
        $script:Posts = [System.Collections.Generic.List[object]]::new()
        Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest {
            if ($Method -eq 'POST') {
                $script:Posts.Add([PSCustomObject]@{ Uri = $Uri; Body = ($Body | ConvertFrom-Json) })
                return
            }
            [PSCustomObject]@{
                value = @(
                    [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.mobileAppDependency'; targetId = 'dep-1'; targetType = 'child'; dependencyType = 'detect' }
                    [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.mobileAppSupersedence'; targetId = 'old-1'; targetType = 'child'; supersedenceType = 'update' }
                    [PSCustomObject]@{ '@odata.type' = '#microsoft.graph.mobileAppSupersedence'; targetId = 'newer'; targetType = 'parent'; supersedenceType = 'update' }
                )
            }
        }
    }

    It 'Keeps the existing child relationships, replaces one to the same app and drops parent relationships' {
        InModuleScope tcs.intune.packaging {
            Set-IntuneAppRelationship -AppId 'app-1' -Relationship ([ordered]@{ '@odata.type' = '#microsoft.graph.mobileAppSupersedence'; targetId = 'old-1'; supersedenceType = 'replace' })
        }
        $script:Posts[0].Uri | Should -Be 'beta/deviceAppManagement/mobileApps/app-1/updateRelationships'
        $relationships = @($script:Posts[0].Body.relationships)
        $relationships.Count | Should -Be 2
        ($relationships | Where-Object targetId -EQ 'dep-1').dependencyType | Should -Be 'detect'
        ($relationships | Where-Object targetId -EQ 'old-1').supersedenceType | Should -Be 'replace'
        $relationships.targetId | Should -Not -Contain 'newer'
    }
}
