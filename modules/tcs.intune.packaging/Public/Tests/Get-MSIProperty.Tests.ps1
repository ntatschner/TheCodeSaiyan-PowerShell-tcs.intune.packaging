BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}
BeforeDiscovery {
    $OnWindows = [System.Environment]::OSVersion.Platform -eq 'Win32NT'
}

Describe 'Get-MSIProperty' {
    It 'Rejects a path that does not exist' {
        { Get-MSIProperty -Path (Join-Path -Path $TestDrive -ChildPath 'missing.msi') } | Should -Throw '*Could not find*'
    }

    It 'Is also available as Get-MSIProperties' {
        (Get-Alias -Name Get-MSIProperties).ResolvedCommandName | Should -Be 'Get-MSIProperty'
    }

    It 'Writes an error instead of output for a file that is not an MSI database' -Skip:(-not $OnWindows) {
        $file = Join-Path -Path $TestDrive -ChildPath 'fake.msi'
        Set-Content -Path $file -Value 'not an msi'
        $result = Get-MSIProperty -Path $file -ErrorVariable msiError -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $msiError | Should -Not -BeNullOrEmpty
    }
}
