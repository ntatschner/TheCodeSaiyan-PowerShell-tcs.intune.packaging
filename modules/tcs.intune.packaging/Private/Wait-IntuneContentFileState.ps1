function Wait-IntuneContentFileState {
    <#
    .SYNOPSIS
        Polls a Win32 app content file until its uploadState reaches the expected state.

    .DESCRIPTION
        GET /deviceAppManagement/mobileApps/{id}/microsoft.graph.win32LobApp/contentVersions/{id}/files/{id}
        (https://learn.microsoft.com/graph/api/intune-apps-mobileappcontentfile-get). The uploadState
        values are listed at
        https://learn.microsoft.com/graph/api/resources/intune-apps-mobileappcontentfile.
        Throws when the state ends in Failed or TimedOut, or after TimeoutSeconds.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$FileUri,

        [Parameter(Mandatory)]
        [ValidateSet('azureStorageUriRequestSuccess', 'azureStorageUriRenewalSuccess', 'commitFileSuccess')]
        [string]$State,

        [int]$TimeoutSeconds = 600,

        [int]$PollIntervalSeconds = 5
    )

    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ($true) {
        $File = Invoke-MgGraphRequest -Method GET -Uri $FileUri -OutputType PSObject -ErrorAction Stop
        if ($File.uploadState -eq $State) {
            return $File
        }
        if ($File.uploadState -like '*Failed' -or $File.uploadState -like '*TimedOut' -or $File.uploadState -eq 'error') {
            throw "The Intune content file is in state '$($File.uploadState)' (waiting for '$State')."
        }
        if ((Get-Date) -ge $Deadline) {
            throw "Timed out after $TimeoutSeconds seconds waiting for the Intune content file to reach '$State' (last state '$($File.uploadState)')."
        }
        Start-Sleep -Seconds $PollIntervalSeconds
    }
}
