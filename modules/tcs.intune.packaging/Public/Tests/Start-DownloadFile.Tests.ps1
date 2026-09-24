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
}
