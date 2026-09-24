function Add-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Assigns a Win32 app to a group, all users or all devices, optionally with an assignment filter.

    .DESCRIPTION
        Uses the mobileApp assign action
        (POST /deviceAppManagement/mobileApps/{id}/assign,
        https://learn.microsoft.com/graph/api/intune-apps-mobileapp-assign). The action replaces all
        assignments of the app, so the existing assignments are read first
        (GET /deviceAppManagement/mobileApps/{id}/assignments) and sent again; an existing assignment
        to the same target is replaced by the new one.

        Targets (https://learn.microsoft.com/graph/api/resources/intune-shared-deviceandappmanagementassignmenttarget):
          User-Group, Device-Group  #microsoft.graph.groupAssignmentTarget (groupId)
          All-Users                 #microsoft.graph.allLicensedUsersAssignmentTarget
          All-Devices               #microsoft.graph.allDevicesAssignmentTarget
        A group is given by ID or display name (looked up with GET /groups; exactly one group must
        match). An assignment filter is given by ID or display name (GET
        /deviceManagement/assignmentFilters) and set with deviceAndAppManagementAssignmentFilterId
        and deviceAndAppManagementAssignmentFilterType (include or exclude).

        Assignment filters are only in the Graph beta endpoint, so assignments are read and written
        with beta: reading them with v1.0 and sending them back would drop existing filters.
        Requires DeviceManagementApps.ReadWrite.All, and Group.Read.All (or GroupMember.Read.All) to
        look up a group by name.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [ValidateSet('User-Group', 'Device-Group', 'All-Users', 'All-Devices')]
        [string]$AssignmentType,

        [string]$AssignmentGroup,

        [ValidateSet('required', 'available', 'uninstall')]
        [string]$Intent = 'required',

        [string]$FilterRuleType,

        [string]$FilterRule
    )

    Test-IntuneAppAssignmentSetting -AssignmentType $AssignmentType -AssignmentGroup $AssignmentGroup -Intent $Intent -FilterRuleType $FilterRuleType -FilterRule $FilterRule
    $GuidPattern = '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'

    switch ($AssignmentType) {
        { $_ -in 'User-Group', 'Device-Group' } {
            if ($AssignmentGroup -match $GuidPattern) {
                $GroupId = $AssignmentGroup
            }
            else {
                $Filter = [System.Uri]::EscapeDataString("displayName eq '$($AssignmentGroup.Replace("'", "''"))'")
                $Groups = @(Get-GraphCollection -Uri "v1.0/groups?`$filter=$Filter&`$select=id,displayName")
                if ($Groups.Count -ne 1) {
                    throw "Found $($Groups.Count) groups with the display name '$AssignmentGroup'; exactly one is needed. Use the group ID instead."
                }
                $GroupId = [string]$Groups[0].id
            }
            $Target = [ordered]@{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId }
        }
        'All-Users' {
            $Target = [ordered]@{ '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget' }
        }
        'All-Devices' {
            $Target = [ordered]@{ '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget' }
        }
    }

    if ($FilterRule) {
        if ($FilterRule -match $GuidPattern) {
            $FilterId = $FilterRule
        }
        else {
            $Filters = @(Get-GraphCollection -Uri 'beta/deviceManagement/assignmentFilters?$select=id,displayName' | Where-Object { $_.displayName -eq $FilterRule })
            if ($Filters.Count -ne 1) {
                throw "Found $($Filters.Count) assignment filters with the name '$FilterRule'; exactly one is needed. Use the filter ID instead."
            }
            $FilterId = [string]$Filters[0].id
        }
        $Target['deviceAndAppManagementAssignmentFilterId'] = $FilterId
        $Target['deviceAndAppManagementAssignmentFilterType'] = $FilterRuleType.ToLowerInvariant()
    }

    $Assignment = [ordered]@{
        '@odata.type' = '#microsoft.graph.mobileAppAssignment'
        intent        = $Intent
        target        = $Target
        settings      = [ordered]@{
            '@odata.type'                = '#microsoft.graph.win32LobAppAssignmentSettings'
            notifications                = 'showAll'
            deliveryOptimizationPriority = 'notConfigured'
        }
    }

    # Keep the existing assignments, except one to the same target
    $AppUri = "beta/deviceAppManagement/mobileApps/$AppId"
    $Assignments = [System.Collections.Generic.List[object]]::new()
    foreach ($Existing in @(Get-GraphCollection -Uri "$AppUri/assignments")) {
        $ExistingTarget = $Existing.target
        $SameTarget = ([string]$ExistingTarget.'@odata.type' -eq $Target['@odata.type']) -and
            ([string]$ExistingTarget.groupId -eq [string]$Target['groupId'])
        if ($SameTarget) {
            Write-Verbose "Replacing the existing $($Existing.intent) assignment to the same target."
            continue
        }
        $Assignments.Add([ordered]@{
                '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                intent        = $Existing.intent
                target        = $ExistingTarget
                settings      = $Existing.settings
            })
    }
    $Assignments.Add($Assignment)

    $Body = @{ mobileAppAssignments = $Assignments.ToArray() } | ConvertTo-Json -Depth 10 -Compress
    Write-Verbose "Assigning app $AppId ($Intent, $AssignmentType)."
    $null = Invoke-MgGraphRequest -Method POST -Uri "$AppUri/assign" -Body $Body -ContentType 'application/json' -ErrorAction Stop
    $Assignment
}
