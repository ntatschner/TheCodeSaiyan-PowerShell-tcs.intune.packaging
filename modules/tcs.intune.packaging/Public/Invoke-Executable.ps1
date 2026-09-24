function Invoke-Executable {
    <#
    .SYNOPSIS
        Runs an executable, waits for it to finish and returns its exit code and output.

    .DESCRIPTION
        The Invoke-Executable function starts an executable with System.Diagnostics.Process, waits for it
        to exit and returns an object with the exit code. When standard output or standard error is
        redirected (the default), the text written to them is returned as well. Redirected streams are
        read while the process runs, so a process that writes a lot of output cannot block.

    .PARAMETER FilePath
        The file name or path of the executable to run, including the extension.

    .PARAMETER Arguments
        The command-line arguments passed to the executable, as a single string.

    .PARAMETER RedirectStandardOutput
        Whether standard output is captured and returned in the StandardOutput property. Default is $true.
        Must be $false when UseShellExecute is $true.

    .PARAMETER RedirectStandardError
        Whether standard error is captured and returned in the StandardError property. Default is $true.
        Must be $false when UseShellExecute is $true.

    .PARAMETER CreateNoWindow
        Whether the process is started without a new window. Default is $true.

    .PARAMETER UseShellExecute
        Whether the operating system shell starts the process. Default is $false.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        ExitCode, StandardOutput and StandardError. The output properties are $null when the stream
        was not redirected.

    .EXAMPLE
        Invoke-Executable -FilePath "setup.exe" -Arguments "/silent /norestart"

        Runs setup.exe with silent installation parameters and returns its exit code and output.

    .EXAMPLE
        $result = Invoke-Executable -FilePath "C:\Tools\mytool.exe" -Arguments "-config test.json" -CreateNoWindow $false -RedirectStandardOutput $false -RedirectStandardError $false
        if ($result.ExitCode -ne 0) { throw "mytool failed with exit code $($result.ExitCode)" }

        Runs mytool.exe in a visible window and checks the exit code.

    .NOTES
        When RedirectStandardOutput or RedirectStandardError is $true, UseShellExecute must be $false.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the file name or path of the executable to be invoked, including the extension.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [parameter(Mandatory = $false, HelpMessage = "Specify arguments that will be passed to the executable.")]
        [ValidateNotNull()]
        [string]$Arguments,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether standard output should be redirected.")]
        [bool]$RedirectStandardOutput = $true,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether standard error output should be redirected.")]
        [bool]$RedirectStandardError = $true,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to start the process without a new window.")]
        [bool]$CreateNoWindow = $true,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to use the operating system shell to start the process.")]
        [bool]$UseShellExecute = $false
    )
    if ($UseShellExecute -and ($RedirectStandardOutput -or $RedirectStandardError)) {
        throw 'RedirectStandardOutput and RedirectStandardError must be $false when UseShellExecute is $true.'
    }

    $ProcessStartInfoObject = New-Object -TypeName 'System.Diagnostics.ProcessStartInfo'
    $ProcessStartInfoObject.FileName = $FilePath
    $ProcessStartInfoObject.CreateNoWindow = $CreateNoWindow
    $ProcessStartInfoObject.UseShellExecute = $UseShellExecute
    $ProcessStartInfoObject.RedirectStandardOutput = $RedirectStandardOutput
    $ProcessStartInfoObject.RedirectStandardError = $RedirectStandardError
    if (-not [string]::IsNullOrEmpty($Arguments)) {
        $ProcessStartInfoObject.Arguments = $Arguments
    }

    $Process = New-Object -TypeName 'System.Diagnostics.Process'
    $Process.StartInfo = $ProcessStartInfoObject
    try {
        try {
            $null = $Process.Start()
        }
        catch {
            throw "$($MyInvocation.MyCommand): Failed to start '$FilePath': $($_.Exception.Message)"
        }

        # Read the redirected streams asynchronously; waiting for exit first can deadlock when a
        # process fills the output buffer.
        $StandardOutputTask = $null
        $StandardErrorTask = $null
        if ($RedirectStandardOutput) {
            $StandardOutputTask = $Process.StandardOutput.ReadToEndAsync()
        }
        if ($RedirectStandardError) {
            $StandardErrorTask = $Process.StandardError.ReadToEndAsync()
        }
        $Process.WaitForExit()

        [PSCustomObject]@{
            ExitCode       = $Process.ExitCode
            StandardOutput = $(if ($StandardOutputTask) { $StandardOutputTask.Result } else { $null })
            StandardError  = $(if ($StandardErrorTask) { $StandardErrorTask.Result } else { $null })
        }
    }
    finally {
        $Process.Dispose()
    }
}
