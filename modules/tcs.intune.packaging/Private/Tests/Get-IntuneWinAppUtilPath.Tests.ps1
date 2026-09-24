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
Describe 'Get-IntuneWinAppUtilPath' {
    It 'Returns a per-user path outside the module folder' {
        $path = InModuleScope tcs.intune.packaging { Get-IntuneWinAppUtilPath }
        $path | Should -BeLike '*IntuneWinAppUtil.exe'
        $path | Should -BeLike '*tcs.intune.packaging*'
        $path | Should -Not -BeLike "$ModuleRoot*"
    }
}
