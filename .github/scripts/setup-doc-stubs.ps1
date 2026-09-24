# Defines stand-ins for the tcs.core functions that tcs.intune.packaging calls while it is imported,
# so the documentation job can load the module when tcs.core is not installed. The signatures match
# tcs.core 0.3.0. The real functions are used when tcs.core is available.
param()

if (-not (Get-Command -Name Get-ModuleConfig -ErrorAction SilentlyContinue)) {
    function global:Get-ModuleConfig {
        param([string]$CommandPath)
        $null = $CommandPath
        return @{
            ModuleName               = 'tcs.intune.packaging'
            ModulePath               = ''
            ModuleVersion            = '0.0.0'
            UpdateWarning            = $false
            UpdateCheckIntervalHours = 24
            Telemetry                = $false
        }
    }
}

if (-not (Get-Command -Name Invoke-TelemetryCollection -ErrorAction SilentlyContinue)) {
    function global:Invoke-TelemetryCollection {
        param(
            [string]$ModuleName,
            [string]$ModuleVersion,
            [string]$CommandName,
            [string]$ExecutionID,
            [string]$Stage,
            [bool]$Failed,
            [object]$Exception,
            [switch]$ClearTimer,
            [string]$URI
        )
    }
}

if (-not (Get-Command -Name Get-ModuleStatus -ErrorAction SilentlyContinue)) {
    function global:Get-ModuleStatus {
        param([switch]$ShowMessage, [string]$ModuleName, [string]$ModulePath, [int]$CacheHours, [switch]$Force)
    }
}

if (-not (Get-Command -Name New-DynamicParameter -ErrorAction SilentlyContinue)) {
    function global:New-DynamicParameter {
        param(
            [string]$Name,
            [type]$ParameterType,
            [switch]$Mandatory,
            [int]$Position,
            [switch]$ValueFromPipelineByPropertyName,
            [string]$HelpMessage,
            [object[]]$ValidateSet,
            [scriptblock]$ValidateScript
        )
        $null = $Position, $ValueFromPipelineByPropertyName, $HelpMessage, $ValidateSet, $ValidateScript, $Mandatory
        $attributes = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
        $attributes.Add((New-Object -TypeName System.Management.Automation.ParameterAttribute))
        [PSCustomObject]@{
            Name      = $Name
            Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList $Name, $ParameterType, $attributes
        }
    }
}
