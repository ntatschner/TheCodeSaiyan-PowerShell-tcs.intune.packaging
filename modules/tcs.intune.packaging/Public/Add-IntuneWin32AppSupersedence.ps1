function Add-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Makes a Win32 app supersede (update or replace) other Win32 apps in Microsoft Intune.

    .DESCRIPTION
        The Add-IntuneWin32AppSupersedence function adds supersedence relationships to the app Id: it
        supersedes each app in SupersededAppId. With SupersedenceType update (default) the new app is
        installed over the old one; with replace the old app is uninstalled first.

        It uses the Microsoft Graph beta action updateRelationships
        (POST /deviceAppManagement/mobileApps/{id}/updateRelationships with
        #microsoft.graph.mobileAppSupersedence), which is not available in Graph v1.0. The app's
        existing supersedence and dependency relationships are kept; a relationship to the same app is
        replaced.

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

    .PARAMETER Id
        The ID of the new (superseding) app. Accepts pipeline input by property name (id).

    .PARAMETER SupersededAppId
        The IDs of the apps that the new app supersedes.

    .PARAMETER SupersedenceType
        update (default) or replace.

    .OUTPUTS
        None

    .EXAMPLE
        Add-IntuneWin32AppSupersedence -Id $newApp.id -SupersededAppId $oldApp.id -SupersedenceType replace

        Makes the new app replace the old app (the old app is uninstalled first).

    .LINK
        https://learn.microsoft.com/graph/api/resources/intune-apps-mobileappsupersedence?view=graph-rest-beta
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$SupersededAppId,

        [ValidateSet('update', 'replace')]
        [string]$SupersedenceType = 'update'
    )
    begin {
        $telemetry = Start-TcsTelemetry
        $lastError = $null
        try {
            $null = Assert-MgGraphConnection
        }
        catch {
            Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $completed = $false
        try {
            if ($SupersededAppId -contains $Id) {
                throw 'An app cannot supersede itself.'
            }
            $Relationships = @(foreach ($TargetId in $SupersededAppId) {
                    [ordered]@{
                        '@odata.type'    = '#microsoft.graph.mobileAppSupersedence'
                        targetId         = $TargetId
                        supersedenceType = $SupersedenceType
                    }
                })
            if ($PSCmdlet.ShouldProcess($Id, "Supersede ($SupersedenceType) $($SupersededAppId -join ', ')")) {
                Set-IntuneAppRelationship -AppId $Id -Relationship $Relationships
            }
            $completed = $true
        }
        catch {
            $lastError = $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
        finally {
            if (-not $completed) {
                Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
            }
        }
    }
    end {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
    }
}
