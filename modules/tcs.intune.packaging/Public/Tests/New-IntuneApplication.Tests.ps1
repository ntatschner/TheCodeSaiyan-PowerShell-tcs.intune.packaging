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
Describe 'New-IntuneApplication' {
    BeforeEach {
        $Source = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Source -ItemType Directory
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'setup.exe') -Value 'x'
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'config.xml') -Value 'x'
        $Output = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Output -ItemType Directory
        $Common = @{
            ApplicationName       = 'MyApp'
            MainInstallerFileName = 'setup.exe'
            OutputFolder          = $Output
            InstallCommand        = 'setup.exe /S'
            UninstallCommand      = 'setup.exe /U'
            DetectionRuleConfig   = @{ Type = 'File' }
            AssignmentType        = 'All-Devices'
            Publisher             = 'Contoso'
        }
    }

    It 'Writes the JSON file with the default description filled in' {
        $result = New-IntuneApplication @Common -SourceFiles $Source -Version '2.0' -NoIntuneWin
        $result.JsonPath | Should -Be (Join-Path -Path $Output -ChildPath 'MyApp.2.0.json')
        $result.IntuneWinPath | Should -BeNullOrEmpty
        $json = Get-Content -Path $result.JsonPath -Raw | ConvertFrom-Json
        $json.ApplicationParameters.Publisher | Should -Be 'Contoso'
        $json.ApplicationParameters.Description | Should -Match 'Publisher: Contoso'
        $json.ApplicationParameters.Description | Should -Match 'Version: 2.0'
        $json.IntuneWinParameters.MainInstallerFileName | Should -Be 'setup.exe'
    }

    It 'Refuses to overwrite the JSON file without -Overwrite' {
        $null = New-IntuneApplication @Common -SourceFiles $Source -NoIntuneWin
        { New-IntuneApplication @Common -SourceFiles $Source -NoIntuneWin } | Should -Throw '*-Overwrite*'
        { New-IntuneApplication @Common -SourceFiles $Source -NoIntuneWin -Overwrite } | Should -Not -Throw
    }

    It 'Throws when the main installer is not one of several source files' {
        $files = Join-Path -Path $Source -ChildPath 'config.xml'
        { New-IntuneApplication @Common -SourceFiles $files -NoIntuneWin } | Should -Throw '*does not exist in the SourceFiles*'
        $Common.MainInstallerFileName = 'other.exe'
        { New-IntuneApplication @Common -SourceFiles (Join-Path -Path $Source -ChildPath 'setup.exe'), $files -NoIntuneWin } | Should -Throw '*does not exist in the SourceFiles*'
    }

    It 'Throws when a source file does not exist' {
        { New-IntuneApplication @Common -SourceFiles (Join-Path -Path $TestDrive -ChildPath 'nope') -NoIntuneWin } | Should -Throw '*does not exist*'
    }

    It 'Runs IntuneWinAppUtil.exe with the source folder and main installer' {
        $tool = Join-Path -Path $TestDrive -ChildPath 'IntuneWinAppUtil.exe'
        Set-Content -Path $tool -Value 'x'
        Mock -ModuleName tcs.intune.packaging Invoke-Executable {
            Set-Content -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -Value 'pkg'
            [PSCustomObject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' }
        }
        $result = New-IntuneApplication @Common -SourceFiles $Source -NoJson -IntuneToolsPath $tool
        $result.IntuneWinPath | Should -Be (Join-Path -Path $Output -ChildPath 'setup.intunewin')
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $tool -and $Arguments -like "*-c `"$Source`"*" -and $Arguments -like '*setup.exe*'
        }
    }

    It 'Publishes the package and removes the files unless -NoCleanUp is used' {
        $tool = Join-Path -Path $TestDrive -ChildPath 'IntuneWinAppUtil.exe'
        Set-Content -Path $tool -Value 'x'
        Mock -ModuleName tcs.intune.packaging Invoke-Executable {
            Set-Content -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -Value 'pkg'
            [PSCustomObject]@{ ExitCode = 0 }
        }
        Mock -ModuleName tcs.intune.packaging Publish-IntuneAppPackage { [PSCustomObject]@{ id = 'app-1' } }
        $result = New-IntuneApplication @Common -SourceFiles $Source -IntuneToolsPath $tool -Publish -Confirm:$false
        $result.App.id | Should -Be 'app-1'
        Should -Invoke -ModuleName tcs.intune.packaging Publish-IntuneAppPackage -Times 1 -Exactly -ParameterFilter {
            $IntuneAppJSONPath -eq (Join-Path -Path $Output -ChildPath 'MyApp.1.0.json') -and $IntuneWinPath -eq (Join-Path -Path $Output -ChildPath 'setup.intunewin')
        }
        Join-Path -Path $Output -ChildPath 'MyApp.1.0.json' | Should -Not -Exist
        Join-Path -Path $Output -ChildPath 'setup.intunewin' | Should -Not -Exist

        $kept = New-IntuneApplication @Common -SourceFiles $Source -IntuneToolsPath $tool -Publish -NoCleanUp -Confirm:$false
        $kept.JsonPath | Should -Exist
    }

    It 'Refuses -Publish without the JSON file or package' {
        { New-IntuneApplication @Common -SourceFiles $Source -NoIntuneWin -Publish } | Should -Throw '*-NoJson or -NoIntuneWin*'
    }
}
