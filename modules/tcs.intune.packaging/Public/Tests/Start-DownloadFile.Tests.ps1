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

Describe 'Start-DownloadFile' {
    It 'Downloads the file with Invoke-WebRequest and creates the folder' {
        Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { Set-Content -Path $OutFile -Value 'data' }
        $folder = Join-Path -Path $TestDrive -ChildPath 'downloads'
        Start-DownloadFile -URL 'https://example.invalid/file.msi' -Path $folder -Name 'file.msi'
        Join-Path -Path $folder -ChildPath 'file.msi' | Should -Exist
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://example.invalid/file.msi' -and $OutFile -eq (Join-Path -Path $folder -ChildPath 'file.msi')
        }
    }

    It 'Throws and removes a partial file when the download fails' {
        Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { Set-Content -Path $OutFile -Value 'partial'; throw 'network down' }
        $folder = Join-Path -Path $TestDrive -ChildPath 'failed'
        { Start-DownloadFile -URL 'https://example.invalid/file.msi' -Path $folder -Name 'file.msi' } | Should -Throw '*network down*'
        Join-Path -Path $folder -ChildPath 'file.msi' | Should -Not -Exist
    }

    It 'Does not create global variables' {
        Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { Set-Content -Path $OutFile -Value 'data' }
        Start-DownloadFile -URL 'https://example.invalid/a.zip' -Path $TestDrive -Name 'a.zip'
        Get-Variable -Name 'DownloadComplete', 'DPCEventArgs' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Downloads nothing with -WhatIf' {
        Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { }
        Start-DownloadFile -URL 'https://example.invalid/a.zip' -Path $TestDrive -Name 'b.zip' -WhatIf
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-WebRequest -Times 0 -Exactly
    }

    Context 'Telemetry' {
        BeforeEach {
            Mock -ModuleName tcs.intune.packaging Invoke-TelemetryCollection { }
        }

        It 'Reports Start and a successful End' {
            Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { Set-Content -Path $OutFile -Value 'data' }
            Start-DownloadFile -URL 'https://example.invalid/c.zip' -Path $TestDrive -Name 'c.zip'
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'Start' -and $CommandName -eq 'Start-DownloadFile' }
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
        }

        It 'Still reports End with -WhatIf' {
            Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { }
            Start-DownloadFile -URL 'https://example.invalid/d.zip' -Path $TestDrive -Name 'd.zip' -WhatIf
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-WebRequest -Times 0 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
        }

        It 'Reports a failed End when the download fails and still throws' {
            Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { throw 'network down' }
            { Start-DownloadFile -URL 'https://example.invalid/e.zip' -Path $TestDrive -Name 'e.zip' } | Should -Throw '*network down*'
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and $Failed -eq $true }
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 0 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
        }
    }
}
