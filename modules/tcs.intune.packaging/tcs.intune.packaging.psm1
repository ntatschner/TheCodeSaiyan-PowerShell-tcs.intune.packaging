#region load private and public functions
# Only the top level of Public/ and Private/ is loaded. Public/Templates holds installer scripts that
# are copied into packages by New-APFDeployment and New-APFConfigDeployment; they must never be
# dot-sourced into the module. Tests live in Public/Tests and Private/Tests.
$Private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })
$Public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })

foreach ($File in @($Private + $Public)) {
    try {
        . $File.FullName
    }
    catch {
        Write-Error -Message "Failed to import '$($File.FullName)': $_"
    }
}
#endregion

#region module config, load telemetry and update check (never blocks import)
try {
    $CurrentConfig = Get-ModuleConfig -CommandPath $PSCommandPath -ErrorAction Stop
    Invoke-TelemetryCollection -ModuleName $CurrentConfig.ModuleName -ModuleVersion $CurrentConfig.ModuleVersion -CommandName 'Import-Module' -ExecutionID ([guid]::NewGuid().ToString()) -Stage 'Module-Load'
    if ($CurrentConfig.UpdateWarning -eq $true) {
        $null = Get-ModuleStatus -ShowMessage -ModuleName $CurrentConfig.ModuleName -ModulePath $CurrentConfig.ModulePath -CacheHours $CurrentConfig.UpdateCheckIntervalHours
    }
}
catch {
    Write-Warning "tcs.intune.packaging configuration could not be loaded; defaults will be used. $($_.Exception.Message)"
}
#endregion

# The plural names are kept as aliases for callers of versions before 0.3.0
Set-Alias -Name 'Get-MSIProperties' -Value 'Get-MSIProperty'
Set-Alias -Name 'New-ApplicationDeploymentGroups' -Value 'New-ApplicationDeploymentGroup'

Export-ModuleMember -Function $Public.BaseName -Alias 'Get-MSIProperties', 'New-ApplicationDeploymentGroups'
