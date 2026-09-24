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
Describe 'New-IntuneAppJSON' {
    It 'Separates the .intunewin parameters from the application parameters' {
        $json = InModuleScope tcs.intune.packaging {
            New-IntuneAppJSON -AppParams @{ ApplicationName = 'App'; MainInstallerFileName = 'setup.exe'; SourceFiles = @('a'); OutputFolder = 'out' }
        }
        $object = $json | ConvertFrom-Json
        $object.ApplicationParameters.ApplicationName | Should -Be 'App'
        $object.ApplicationParameters.PSObject.Properties.Name | Should -Not -Contain 'MainInstallerFileName'
        $object.IntuneWinParameters.MainInstallerFileName | Should -Be 'setup.exe'
        $object.IntuneWinParameters.OutputFolder | Should -Be 'out'
    }

    It 'Does not change the hashtable it is given' {
        InModuleScope tcs.intune.packaging {
            $params = @{ ApplicationName = 'App'; MainInstallerFileName = 'setup.exe' }
            $null = New-IntuneAppJSON -AppParams $params
            $params.ContainsKey('MainInstallerFileName') | Should -BeTrue
        }
    }
}
