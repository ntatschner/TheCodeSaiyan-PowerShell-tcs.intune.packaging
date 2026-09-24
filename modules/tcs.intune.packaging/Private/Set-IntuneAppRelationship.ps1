function Set-IntuneAppRelationship {
    <#
    .SYNOPSIS
        Adds supersedence or dependency relationships to a Win32 app.

    .DESCRIPTION
        Uses the beta updateRelationships action
        (POST /deviceAppManagement/mobileApps/{id}/updateRelationships,
        https://learn.microsoft.com/graph/api/intune-apps-mobileapp-updaterelationships?view=graph-rest-beta),
        which is not in Graph v1.0. The action replaces the app's relationships, so the existing
        relationships in which the other app is the child (targetType 'child') are read first
        (GET /deviceAppManagement/mobileApps/{id}/relationships) and sent again; an existing
        relationship to the same target app is replaced by the new one.
        Relationship types: #microsoft.graph.mobileAppSupersedence (supersedenceType update or replace)
        and #microsoft.graph.mobileAppDependency (dependencyType detect or autoInstall).
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Called by the public Add-IntuneWin32App* commands after their ShouldProcess check.')]
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary[]]$Relationship
    )

    $AppUri = "beta/deviceAppManagement/mobileApps/$AppId"
    $NewTargets = @($Relationship | ForEach-Object { [string]$_['targetId'] })
    $Relationships = [System.Collections.Generic.List[object]]::new()
    foreach ($Existing in @(Get-GraphCollection -Uri "$AppUri/relationships")) {
        if ([string]$Existing.targetType -ne 'child' -or [string]$Existing.targetId -in $NewTargets) {
            continue
        }
        $Kept = [ordered]@{ '@odata.type' = [string]$Existing.'@odata.type'; targetId = [string]$Existing.targetId }
        if ($Existing.'@odata.type' -eq '#microsoft.graph.mobileAppSupersedence') {
            $Kept['supersedenceType'] = [string]$Existing.supersedenceType
        }
        elseif ($Existing.'@odata.type' -eq '#microsoft.graph.mobileAppDependency') {
            $Kept['dependencyType'] = [string]$Existing.dependencyType
        }
        $Relationships.Add($Kept)
    }
    foreach ($Item in $Relationship) {
        $Relationships.Add($Item)
    }
    $Body = @{ relationships = $Relationships.ToArray() } | ConvertTo-Json -Depth 5 -Compress
    $null = Invoke-MgGraphRequest -Method POST -Uri "$AppUri/updateRelationships" -Body $Body -ContentType 'application/json' -ErrorAction Stop
}
