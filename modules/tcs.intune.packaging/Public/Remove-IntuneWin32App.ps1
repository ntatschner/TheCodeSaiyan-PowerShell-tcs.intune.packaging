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
