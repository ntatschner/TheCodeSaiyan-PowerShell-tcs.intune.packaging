function Remove-IntuneWin32App {
    <#
    .SYNOPSIS
        Deletes a Win32 app from Microsoft Intune.

    .DESCRIPTION
        The Remove-IntuneWin32App function reads the app first and only deletes it
        (DELETE /deviceAppManagement/mobileApps/{id}) when it is a Win32 app (win32LobApp). You are asked
        to confirm each app; use -Confirm:$false to skip that and -WhatIf to see what would be deleted.

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

    .PARAMETER Id
        The ID of the app. Accepts pipeline input, for example from Get-IntuneWin32App.

    .OUTPUTS
        None

    .EXAMPLE
        Remove-IntuneWin32App -Id '00000000-0000-0000-0000-000000000000' -WhatIf

        Shows which app would be deleted.

    .EXAMPLE
        Get-IntuneWin32App -Name 'MyApp (old)' | Remove-IntuneWin32App

        Deletes the Win32 apps named "MyApp (old)" after confirmation.

    .LINK
        https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-delete
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Id
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
            foreach ($AppId in $Id) {
                $AppUri = "v1.0/deviceAppManagement/mobileApps/$([System.Uri]::EscapeDataString($AppId))"
                $App = Invoke-MgGraphRequest -Method GET -Uri $AppUri -OutputType PSObject -ErrorAction Stop
                if ($App.'@odata.type' -ne '#microsoft.graph.win32LobApp') {
                    Write-Error -Message "The app '$AppId' is not a Win32 app ($($App.'@odata.type')); it was not deleted." -TargetObject $AppId
                    continue
                }
                if ($PSCmdlet.ShouldProcess("$($App.displayName) ($AppId)", 'Delete Intune Win32 app')) {
                    $null = Invoke-MgGraphRequest -Method DELETE -Uri $AppUri -ErrorAction Stop
                }
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
