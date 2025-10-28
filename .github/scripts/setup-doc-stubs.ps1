param()

if (-not (Get-Command -Name Get-ModuleConfig -ErrorAction SilentlyContinue)) {
    function global:Get-ModuleConfig {
        param($CommandPath)
        return @{ ModuleName = 'tcs.intune.packaging'; ModulePath = ''; BasicTelemetry = 'False' }
    }
}

if (-not (Get-Command -Name Invoke-TelemetryCollection -ErrorAction SilentlyContinue)) {
    function global:Invoke-TelemetryCollection {
        param([hashtable]$TelemetryArgs, [string]$Stage, [switch]$ClearTimer, [switch]$Failed, $Exception, [switch]$Minimal)
    }
}
