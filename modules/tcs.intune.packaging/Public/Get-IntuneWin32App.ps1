function Get-IntuneWin32App {
    <#
    .SYNOPSIS
        Gets Win32 apps from Microsoft Intune.

    .DESCRIPTION
        The Get-IntuneWin32App function reads Win32 apps (win32LobApp) with Microsoft Graph v1.0:
          - With Id: GET /deviceAppManagement/mobileApps/{id}. An app that is not a Win32 app is an error.
          - With Name: the Win32 apps whose display name is Name (exact match, not case-sensitive).
          - Without either: all Win32 apps in the tenant.

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.Read.All (or DeviceManagementApps.ReadWrite.All).

    .PARAMETER Id
        The ID of the app.

    .PARAMETER Name
        The display name of the app.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        The win32LobApp objects as returned by Microsoft Graph.

    .EXAMPLE
        Get-IntuneWin32App -Name 'MyApp'

        Gets the Win32 apps named MyApp.

    .EXAMPLE
        Get-IntuneWin32App | Select-Object id, displayName

        Lists all Win32 apps.

    .LINK
        https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name
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
            switch ($PSCmdlet.ParameterSetName) {
                'Id' {
                    $App = Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceAppManagement/mobileApps/$([System.Uri]::EscapeDataString($Id))" -OutputType PSObject -ErrorAction Stop
                    if ($App.'@odata.type' -ne '#microsoft.graph.win32LobApp') {
                        throw "The app '$Id' is not a Win32 app ($($App.'@odata.type'))."
                    }
                    $App
                }
                'Name' {
                    $Filter = [System.Uri]::EscapeDataString("displayName eq '$($Name.Replace("'", "''"))'")
                    Get-GraphCollection -Uri "v1.0/deviceAppManagement/mobileApps?`$filter=$Filter" |
                        Where-Object { $_.'@odata.type' -eq '#microsoft.graph.win32LobApp' }
                }
                'All' {
                    Get-GraphCollection -Uri "v1.0/deviceAppManagement/mobileApps?`$filter=$([System.Uri]::EscapeDataString("isof('microsoft.graph.win32LobApp')"))"
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
