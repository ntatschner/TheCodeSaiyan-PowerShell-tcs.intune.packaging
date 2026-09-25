BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
    . (Join-Path -Path $PSScriptRoot -ChildPath '../../../../tests/TestHelpers/New-TestIntuneWin.ps1')
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}
Describe 'New-IntuneWin32AppPackage' {
    BeforeEach {
        $Source = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Source -ItemType Directory
        Set-Content -Path (Join-Path -Path $Source -ChildPath 'setup.exe') -Value 'x'
        $Output = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        $null = New-Item -Path $Output -ItemType Directory
        $Tool = Join-Path -Path $TestDrive -ChildPath 'IntuneWinAppUtil.exe'
        Set-Content -Path $Tool -Value 'x'
        # Stands in for IntuneWinAppUtil.exe: writes a real .intunewin (zip with Detection.xml)
        Mock -ModuleName tcs.intune.packaging Invoke-Executable {
            $null = New-TestIntuneWin -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -ContentSize 2048
            [PSCustomObject]@{ ExitCode = 0; StandardOutput = $null; StandardError = $null }
        }
        Mock -ModuleName tcs.intune.packaging Get-IntunePackagingTool { }
        Mock -ModuleName tcs.intune.packaging Confirm-ToolDownload { $false }
    }

    It 'Returns the package details read from the package metadata' {
        $result = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool
        $result.Path | Should -Be (Join-Path -Path $Output -ChildPath 'setup.intunewin')
        $result.Name | Should -Be 'setup.exe'
        $result.FileName | Should -Be 'IntunePackage.intunewin'
        $result.SetupFile | Should -Be 'setup.exe'
        $result.UnencryptedContentSize | Should -Be 2000
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly -ParameterFilter { $FilePath -eq $Tool -and $Arguments -like '*-q' }
    }

    It 'Does not use the optional IntuneWin32App module' {
        (Get-Command -Name New-IntuneWin32AppPackage).Definition | Should -Not -Match 'Get-IntuneWin32AppMetaData'
    }

    It 'Removes a trailing separator from the output folder so it cannot escape the closing quote' {
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder "$Output$([System.IO.Path]::DirectorySeparatorChar)" -IntuneWinAppUtilPath $Tool
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly -ParameterFilter { $Arguments -like "*-o `"$Output`" -q" }
    }

    It 'Writes a non-terminating error and does not overwrite an existing package without -Force' {
        Set-Content -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -Value 'old'
        $result = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -ErrorVariable pkgError -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        "$pkgError" | Should -Match '-Force'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 0 -Exactly
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -Force
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly
    }

    It 'Throws when the setup file is not in the source folder' {
        { New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'missing.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool } | Should -Throw '*missing.exe*'
    }

    It 'Throws when the source or output folder does not exist' {
        { New-IntuneWin32AppPackage -SourceFolder (Join-Path -Path $TestDrive -ChildPath 'nope') -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool } | Should -Throw '*source folder*'
        { New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder (Join-Path -Path $TestDrive -ChildPath 'nope') -IntuneWinAppUtilPath $Tool } | Should -Throw '*output folder*'
    }

    It 'Throws when IntuneWinAppUtil.exe fails' {
        Mock -ModuleName tcs.intune.packaging Invoke-Executable { [PSCustomObject]@{ ExitCode = 2; StandardOutput = ''; StandardError = 'bad setup' } }
        { New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool } | Should -Throw '*exit code 2*bad setup*'
    }

    It 'Creates nothing with -WhatIf' {
        $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -WhatIf
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 0 -Exactly
    }

    Context 'Finding and downloading IntuneWinAppUtil.exe' {
        It 'Uses the default tool when only a literal path test finds it (no download)' {
            # Test-Path -Path treats [ ] as wildcards; the old check used -or and downloaded the tool anyway
            $bracketFolder = Join-Path -Path $TestDrive -ChildPath 'tools[1]'
            $null = New-Item -Path $bracketFolder -ItemType Directory -Force
            $bracketTool = Join-Path -Path $bracketFolder -ChildPath 'IntuneWinAppUtil.exe'
            Set-Content -LiteralPath $bracketTool -Value 'x'
            Mock -ModuleName tcs.intune.packaging Get-IntuneWinAppUtilPath { $bracketTool }
            $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output
            Should -Invoke -ModuleName tcs.intune.packaging Get-IntunePackagingTool -Times 0 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Confirm-ToolDownload -Times 0 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 1 -Exactly -ParameterFilter { $FilePath -eq $bracketTool }
        }

        It 'Asks before downloading a missing tool and stops when the download is declined' {
            $missing = Join-Path -Path $TestDrive -ChildPath 'no-tool/IntuneWinAppUtil.exe'
            Mock -ModuleName tcs.intune.packaging Get-IntuneWinAppUtilPath { $missing }
            { New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output } | Should -Throw '*-AllowDownload*'
            Should -Invoke -ModuleName tcs.intune.packaging Confirm-ToolDownload -Times 1 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Get-IntunePackagingTool -Times 0 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-Executable -Times 0 -Exactly
        }

        It 'Downloads the pinned release without asking with -AllowDownload' {
            $missing = Join-Path -Path $TestDrive -ChildPath 'download/IntuneWinAppUtil.exe'
            Mock -ModuleName tcs.intune.packaging Get-IntuneWinAppUtilPath { $missing }
            Mock -ModuleName tcs.intune.packaging Get-IntunePackagingTool { [System.IO.FileInfo]$Tool }
            $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -AllowDownload
            Should -Invoke -ModuleName tcs.intune.packaging Confirm-ToolDownload -Times 0 -Exactly
            Should -Invoke -ModuleName tcs.intune.packaging Get-IntunePackagingTool -Times 1 -Exactly -ParameterFilter { $DownloadTag -eq 'v1.8.6' -and $Path -eq (Split-Path -Path $missing -Parent) }
        }

        It 'Does not download when an explicit IntuneWinAppUtilPath is missing' {
            { New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath (Join-Path -Path $TestDrive -ChildPath 'x/IntuneWinAppUtil.exe') -AllowDownload } | Should -Throw '*was not found*'
            Should -Invoke -ModuleName tcs.intune.packaging Get-IntunePackagingTool -Times 0 -Exactly
        }
    }

    Context 'Telemetry' {
        BeforeEach {
            Mock -ModuleName tcs.intune.packaging Invoke-TelemetryCollection { }
        }

        It 'Reports a failed End when packaging fails' {
            { New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'missing.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool } | Should -Throw
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and $Failed -eq $true }
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 0 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
        }

        It 'Reports a failed End when the package exists and -Force is not used' {
            Set-Content -Path (Join-Path -Path $Output -ChildPath 'setup.intunewin') -Value 'old'
            $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool -ErrorAction SilentlyContinue
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and $Failed -eq $true }
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 0 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
        }

        It 'Reports a successful End' {
            $null = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile 'setup.exe' -OutputFolder $Output -IntuneWinAppUtilPath $Tool
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
        }
    }
}
