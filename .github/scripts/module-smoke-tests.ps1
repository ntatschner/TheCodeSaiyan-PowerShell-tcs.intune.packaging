# Smoke tests run by the shared CI validation workflow (smoke-test-script-path in ci-validate.yml).
# Imports the module offline and exercises commands that are safe on every OS.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'CI console output for the workflow log.')]
param()

$moduleName = 'tcs.intune.packaging'
$repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$moduleDirectory = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'modules') -ChildPath $moduleName
$moduleManifest = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psd1"

if (-not (Test-Path -Path $moduleManifest)) {
    throw "Module manifest not found at path: $moduleManifest"
}

# Keep the smoke test offline and away from the real user profile
$env:TCS_SKIP_UPDATE_CHECK = '1'
$env:TCS_TELEMETRY_OPTOUT = '1'
$env:TCS_CONFIG_ROOT = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "tcs-smoke-$([guid]::NewGuid().ToString('N'))"
$workFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "tcs-intune-smoke-$([guid]::NewGuid().ToString('N'))"

try {
    Write-Host "Importing $moduleName from $moduleManifest" -ForegroundColor Cyan
    Import-Module -Name $moduleManifest -Force -ErrorAction Stop
    $null = New-Item -Path $workFolder -ItemType Directory -Force

    # The commands below are safe on every OS: no network, Intune, Graph, COM or admin rights needed
    $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType Registry -Path 'HKEY_LOCAL_MACHINE\Software\Smoke' -ValueName 'Version' -Operator equal -DataType version -Value '1.0'
    if ($rule['@odata.type'] -ne '#microsoft.graph.win32LobAppRegistryRule' -or $rule['operationType'] -ne 'version' -or $rule['comparisonValue'] -ne '1.0') {
        throw "New-IntuneWin32Rule returned an unexpected registry rule: $($rule | Out-String)"
    }

    Set-Content -Path (Join-Path -Path $workFolder -ChildPath 'setup.exe') -Value 'smoke'
    $packageFile = New-PackageJSON -PackageName 'Smoke' -Version '1.0' -Description 'Smoke test' -Author 'CI' -SourceDirectory $workFolder -MainInstaller 'setup.exe' -WarningAction SilentlyContinue
    $package = Get-Content -Path $packageFile.FullName -Raw | ConvertFrom-Json
    if ($package.PackageName -ne 'Smoke' -or $package.MainInstaller -ne 'setup.exe' -or $package.AllFiles -ne 'setup.exe') {
        throw "New-PackageJSON wrote unexpected content: $($package | Out-String)"
    }

    $groups = @(New-ApplicationDeploymentGroup -ApplicationName 'smoke app')
    $expectedGroups = @('Intune-AG-SmokeApp-Available', 'Intune-AG-SmokeApp-Required', 'Intune-App-SmokeApp-Test', 'Intune-App-SmokeApp-Phase1')
    if ((@($groups.GroupName) -join ',') -ne ($expectedGroups -join ',')) {
        throw "New-ApplicationDeploymentGroup returned unexpected group names: $(@($groups.GroupName) -join ', ')"
    }

    $exported = @((Get-Module $moduleName).ExportedFunctions.Keys)
    $expected = @((Import-PowerShellDataFile -Path $moduleManifest).FunctionsToExport)
    $missing = $expected | Where-Object { $_ -notin $exported }
    if ($missing -or $exported.Count -ne $expected.Count) {
        throw "Exported functions do not match the manifest. Expected $($expected.Count), got $($exported.Count): $($exported -join ', ')"
    }

    Write-Host 'All smoke tests passed successfully.' -ForegroundColor Green
}
finally {
    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $workFolder -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:TCS_CONFIG_ROOT -Recurse -Force -ErrorAction SilentlyContinue
}
