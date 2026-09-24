function Add-IntuneWin32AppDependency {
    <#
    .SYNOPSIS
        Makes a Win32 app depend on other Win32 apps in Microsoft Intune.

    .DESCRIPTION
        The Add-IntuneWin32AppDependency function adds dependency relationships to the app Id: it
        depends on each app in DependsOnAppId. With DependencyType autoInstall (default) Intune installs
        a missing dependency before the app; with detect the app is only installed when the dependency
        is already detected.

        It uses the Microsoft Graph beta action updateRelationships
        (POST /deviceAppManagement/mobileApps/{id}/updateRelationships with
        #microsoft.graph.mobileAppDependency), which is not available in Graph v1.0. The app's
        existing supersedence and dependency relationships are kept; a relationship to the same app is
        replaced.

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

    .PARAMETER Id
        The ID of the app that has the dependencies. Accepts pipeline input by property name (id).

    .PARAMETER DependsOnAppId
        The IDs of the apps that the app depends on.

    .PARAMETER DependencyType
        autoInstall (default) or detect.

    .OUTPUTS
        None

    .EXAMPLE
        Add-IntuneWin32AppDependency -Id $app.id -DependsOnAppId $runtime.id

        Makes the app depend on the runtime app; Intune installs the runtime first when it is missing.

    .LINK
        https://learn.microsoft.com/graph/api/resources/intune-apps-mobileappdependency?view=graph-rest-beta
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$DependsOnAppId,

        [ValidateSet('autoInstall', 'detect')]
        [string]$DependencyType = 'autoInstall'
    )
    begin {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        $TelemetryFailed = $false
        try {
            $null = Assert-MgGraphConnection
        }
        catch {
            $TelemetryFailed = $true
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        try {
            if ($DependsOnAppId -contains $Id) {
                throw 'An app cannot depend on itself.'
            }
            $Relationships = @(foreach ($TargetId in $DependsOnAppId) {
                    [ordered]@{
                        '@odata.type'  = '#microsoft.graph.mobileAppDependency'
                        targetId       = $TargetId
                        dependencyType = $DependencyType
                    }
                })
            if ($PSCmdlet.ShouldProcess($Id, "Add dependency ($DependencyType) on $($DependsOnAppId -join ', ')")) {
                Set-IntuneAppRelationship -AppId $Id -Relationship $Relationships
            }
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
