function Read-IntuneAppJson {
    <#
    .SYNOPSIS
        Reads the application JSON written by New-IntuneApplication.

    .DESCRIPTION
        Returns ApplicationParameters and the detection and requirement rules (DetectionRuleConfig
        and RequirementRuleConfig) converted to hashtables. The rules must be Win32 app rules made
        with New-IntuneWin32Rule (they have an '@odata.type'). With IgnoreRules the rules are not read
        (the caller has its own).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$IgnoreRules
    )

    $AppParameters = (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json).ApplicationParameters
    if (-not $AppParameters -or [string]::IsNullOrEmpty($AppParameters.ApplicationName)) {
        throw "'$Path' does not contain ApplicationParameters.ApplicationName."
    }
    $RuleConfigs = @()
    if (-not $IgnoreRules) {
        $RuleConfigs = @($AppParameters.DetectionRuleConfig, $AppParameters.RequirementRuleConfig)
    }
    $Rules = @(foreach ($Config in $RuleConfigs) {
            foreach ($Rule in @($Config | Where-Object { $_ })) {
                $Hashtable = @{}
                foreach ($Property in $Rule.PSObject.Properties) {
                    $Hashtable[$Property.Name] = $Property.Value
                }
                if (-not $Hashtable.ContainsKey('@odata.type')) {
                    throw "The rule configuration in '$Path' is not a Win32 app rule. Create the rules with New-IntuneWin32Rule, or pass them with -Rules."
                }
                $Hashtable
            }
        })
    [PSCustomObject]@{
        AppParameters = $AppParameters
        DisplayName   = [string]$AppParameters.ApplicationName
        Rules         = $Rules
    }
}
