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

Describe 'Invoke-Executable' {
    BeforeAll {
        $PowerShellPath = (Get-Process -Id $PID).Path
    }

    It 'Returns the exit code of the process' {
        $result = Invoke-Executable -FilePath $PowerShellPath -Arguments '-NoProfile -NonInteractive -Command "exit 3"'
        $result.ExitCode | Should -Be 3
    }

    It 'Returns standard output and standard error' {
        $result = Invoke-Executable -FilePath $PowerShellPath -Arguments '-NoProfile -NonInteractive -Command "[Console]::Out.Write(''out-text''); [Console]::Error.Write(''err-text'')"'
        $result.ExitCode | Should -Be 0
        $result.StandardOutput | Should -Match 'out-text'
        $result.StandardError | Should -Match 'err-text'
    }

    It 'Does not block when the process writes more output than the pipe buffer holds' {
        $result = Invoke-Executable -FilePath $PowerShellPath -Arguments '-NoProfile -NonInteractive -Command "[Console]::Out.Write((''x'' * 200000))"'
        $result.ExitCode | Should -Be 0
        $result.StandardOutput.Length | Should -BeGreaterOrEqual 200000
    }

    It 'Returns null output when the streams are not redirected' {
        $result = Invoke-Executable -FilePath $PowerShellPath -Arguments '-NoProfile -NonInteractive -Command "exit 0"' -RedirectStandardOutput $false -RedirectStandardError $false
        $result.StandardOutput | Should -BeNullOrEmpty
        $result.StandardError | Should -BeNullOrEmpty
    }

    It 'Rejects redirection together with UseShellExecute' {
        { Invoke-Executable -FilePath $PowerShellPath -UseShellExecute $true } | Should -Throw '*UseShellExecute*'
    }

    It 'Throws a clear error when the executable does not exist' {
        { Invoke-Executable -FilePath (Join-Path -Path $TestDrive -ChildPath 'missing.exe') } | Should -Throw '*Failed to start*'
    }
}
