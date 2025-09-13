#Requires -PSEdition Core
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Devices.CorporateManagement

Class IntunePackages : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        try {
            $PackagedApps = Get-MgDeviceAppManagementMobileApp -All -Filter "NOT(startswith(Notes, 'PmpAppId:') or startswith(Notes, 'PmpUpdateId:'))" -Property DisplayName, CreatedDateTime, id, Assignments -ExpandProperty Assignments | Where-Object -FilterScript { $_.Assignments.Count -gt 0 } | Group-Object DisplayName | ForEach-Object {
                $_.Group | Sort-Object CreatedDateTime -Descending | Select-Object -First 1
            }
            $Packages = ForEach ($P in $PackagedApps) {
                "$($P.DisplayName) | $($P.Id)"
            }
            return [string[]] $Packages
        }
        catch {
            Write-Error -Message "Failed to retrieve Intune apps. Error: $_"
            return [NullString[]] $null
        }
    }
}
