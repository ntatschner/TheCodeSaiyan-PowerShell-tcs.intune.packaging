function Assert-MgGraphConnection {
    <#
    .SYNOPSIS
        Throws when Microsoft.Graph.Authentication is missing or there is no Graph connection.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param ()

    foreach ($Command in 'Get-MgContext', 'Invoke-MgGraphRequest') {
        if (-not (Get-Command -Name $Command -ErrorAction SilentlyContinue)) {
            throw "$Command is not available. Install the Microsoft.Graph.Authentication module and connect with Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All."
        }
    }
    $Context = Get-MgContext
    if (-not $Context) {
        throw 'You are not connected to Microsoft Graph. Connect with Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All first.'
    }
    $Context
}
