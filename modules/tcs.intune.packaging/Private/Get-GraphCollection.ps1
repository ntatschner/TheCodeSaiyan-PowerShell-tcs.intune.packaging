function Get-GraphCollection {
    <#
    .SYNOPSIS
        Returns every item of a Microsoft Graph collection, following @odata.nextLink.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory)]
        [string]$Uri
    )

    $NextUri = $Uri
    while ($NextUri) {
        $Response = Invoke-MgGraphRequest -Method GET -Uri $NextUri -OutputType PSObject -ErrorAction Stop
        foreach ($Item in @($Response.value)) {
            if ($null -ne $Item) {
                $Item
            }
        }
        # Only a single response object carries a next link; anything else ends the loop
        $NextUri = $null
        if ($Response -isnot [array] -and $Response.'@odata.nextLink' -is [string]) {
            $NextUri = $Response.'@odata.nextLink'
        }
    }
}
