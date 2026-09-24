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

Describe 'Test-IntuneLogoImage' {
    It 'Returns false for a missing file' {
        InModuleScope tcs.intune.packaging -Parameters @{ Path = (Join-Path -Path $TestDrive -ChildPath 'missing.png') } {
            Test-IntuneLogoImage -Path $Path -ErrorAction SilentlyContinue | Should -BeFalse
        }
    }

    It 'Returns false for a file that is not a PNG or JPG' {
        $file = Join-Path -Path $TestDrive -ChildPath 'logo.gif'
        Set-Content -Path $file -Value 'x'
        InModuleScope tcs.intune.packaging -Parameters @{ Path = $file } {
            Test-IntuneLogoImage -Path $Path -ErrorAction SilentlyContinue | Should -BeFalse
        }
    }

    It 'Checks the image size (<Size> pixels)' -Skip:(-not $OnWindows) -ForEach @(
        @{ Size = 64; Expected = $true }
        @{ Size = 300; Expected = $false }
    ) {
        Add-Type -AssemblyName System.Drawing
        $file = Join-Path -Path $TestDrive -ChildPath "logo$Size.jpeg"
        $bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Size, $Size
        $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $bitmap.Dispose()
        InModuleScope tcs.intune.packaging -Parameters @{ Path = $file; Expected = $Expected } {
            Test-IntuneLogoImage -Path $Path -ErrorAction SilentlyContinue | Should -Be $Expected
        }
    }
}
