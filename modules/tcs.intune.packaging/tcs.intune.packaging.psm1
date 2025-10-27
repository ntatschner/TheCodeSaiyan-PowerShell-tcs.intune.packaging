#region Load Classes First (must be loaded before functions that use them)
$Classes = @(
    Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue
)
foreach ($Class in $Classes) {
    try {
        . $Class.FullName
    }
    catch {
        Write-Error -Message "Failed to import class at $($Class.FullName): $_"
    }
}
#endregion

#region get public and private function definition files.
$Public = @(
    Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue
)
$Private = @(
    Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue
)
#endregion

#region source the files
foreach ($Function in @($Public + $Private)) {
    $FunctionPath = $Function.fullname
    try {
        . $FunctionPath # dot source function
    }
    catch {
        Write-Error -Message "Failed to import function at $($FunctionPath): $_"
    }
}
#endregion

#region read in or create an initial config file and variable
#. "$PSScriptRoot\Config.ps1" # uncomment to source config parsing logic
#endregion

#region set variables visible to the module and its functions only
$Date = Get-Date -UFormat "%Y.%m.%d"
$Time = Get-Date -UFormat "%H:%M:%S"
. "$PSScriptRoot\Colors.ps1"
#endregion

#region export Public functions ($Public.BaseName) for WIP modules
Export-ModuleMember -Function $Public.Basename
#endregion

#region export Classes
# Export classes to make them available to module consumers
$ClassNames = $Classes | ForEach-Object { 
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'Class\s+(\w+)') {
        $matches[1]
    }
}
if ($ClassNames) {
    foreach ($ClassName in $ClassNames) {
        Export-ModuleMember -Variable $ClassName -ErrorAction SilentlyContinue
    }
}
#endregion

# Module Config setup and import
try {
    $CurrentConfig = Get-ModuleConfig -CommandPath $PSCommandPath -ErrorAction Stop
}
catch {
    Write-Error "Module Import error: `n $($_.Exception.Message)"
}

# Generate execution ID
$ExecutionID = [System.Guid]::NewGuid().ToString()

$TelmetryArgs = @{
    ModuleName    = $CurrentConfig.ModuleName
    ModulePath    = $CurrentConfig.ModulePath
    ModuleVersion = $MyInvocation.MyCommand.Module.Version
    ExecutionID   = $ExecutionID
    CommandName   = $MyInvocation.MyCommand.Name
    URI           = 'https://NOTYETDEFINED.com'
    ClearTimer    = $true
    Stage         = 'Module-Load'
}

if ($CurrentConfig.BasicTelemetry -eq 'True') {
    Invoke-TelemetryCollection -Minimal @TelmetryArgs
}
else {
    Invoke-TelemetryCollection @TelmetryArgs
}

if ($CurrentConfig.UpdateWarning -eq 'True') {
    Get-ModuleStatus -ShowMessage -ModuleName $CurrentConfig.ModuleName -ModulePath $CurrentConfig.ModulePath
}
