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

Describe 'Get-IntunePackagingTool' {
    BeforeAll {
        # Builds a zip that looks like a GitHub release archive of the Win32 Content Prep Tool
        $ArchiveSource = Join-Path -Path $TestDrive -ChildPath 'archive-src'
        $null = New-Item -Path (Join-Path -Path $ArchiveSource -ChildPath 'Microsoft-Win32-Content-Prep-Tool-1.8.6') -ItemType Directory -Force
        Set-Content -Path (Join-Path -Path $ArchiveSource -ChildPath 'Microsoft-Win32-Content-Prep-Tool-1.8.6/IntuneWinAppUtil.exe') -Value 'tool'
        $ArchivePath = Join-Path -Path $TestDrive -ChildPath 'release.zip'
        Compress-Archive -Path (Join-Path -Path $ArchiveSource -ChildPath '*') -DestinationPath $ArchivePath
    }

    BeforeEach {
        Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { Copy-Item -Path $ArchivePath -Destination $OutFile }
        Mock -ModuleName tcs.intune.packaging Invoke-RestMethod { [PSCustomObject]@{ tag_name = 'v9.9.9' } }
        $Target = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
    }

    It 'Downloads the latest release and copies IntuneWinAppUtil.exe' {
        $file = Get-IntunePackagingTool -Path $Target
        $file.Name | Should -Be 'IntuneWinAppUtil.exe'
        Join-Path -Path $Target -ChildPath 'IntuneWinAppUtil.exe' | Should -Exist
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/tags/v9.9.9.zip'
        }
    }

    It 'Downloads the requested tag' {
        $null = Get-IntunePackagingTool -Path $Target -DownloadTag 'v1.8.6'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-RestMethod -Times 0 -Exactly
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/tags/v1.8.6.zip'
        }
    }

    It 'Refuses to overwrite an existing tool without -Force' {
        $null = Get-IntunePackagingTool -Path $Target -DownloadTag 'v1.8.6'
        { Get-IntunePackagingTool -Path $Target -DownloadTag 'v1.8.6' } | Should -Throw '*-Force*'
        { Get-IntunePackagingTool -Path $Target -DownloadTag 'v1.8.6' -Force } | Should -Not -Throw
    }

    It 'Throws instead of exiting the session when the download fails' {
        Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { throw 'offline' }
        { Get-IntunePackagingTool -Path $Target -DownloadTag 'v1.8.6' } | Should -Throw '*offline*'
    }

    It 'Removes its temporary files' {
        $before = @(Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter 'IntuneWinAppUtil-*' -ErrorAction SilentlyContinue).Count
        $null = Get-IntunePackagingTool -Path $Target -DownloadTag 'v1.8.6'
        @(Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter 'IntuneWinAppUtil-*' -ErrorAction SilentlyContinue).Count | Should -Be $before
    }
}
