function Invoke-IntuneWinAppUtil {
    <#
    .SYNOPSIS
        Runs IntuneWinAppUtil.exe to wrap a source folder into a .intunewin package.

    .DESCRIPTION
        Shared by New-IntuneWin32AppPackage, New-IntuneApplication and the APF commands.

        Tool: ToolPath when given (it must exist); otherwise the per-user tool path
        (Get-IntuneWinAppUtilPath). When that is missing the tool is downloaded with
        Get-IntunePackagingTool (release DownloadTag, signature-checked) only after confirmation, or
        without asking when AllowDownload is used. Declining stops with an error.

        Arguments: -c <source> -s <setup file> -o <output> -q, each path quoted. Trailing path
        separators are removed first, because a backslash before the closing quote would escape it
        ("C:\Out\" would reach the tool as C:\Out"); a drive root becomes "C:\.".

        The tool writes "<setup file name without extension>.intunewin" to OutputFolder. An existing
        file is replaced only with Overwrite. With PackageName the output is renamed to
        "<PackageName>.intunewin". Throws when the tool fails or creates no package; returns the file.
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [string]$SourceFolder,

        [Parameter(Mandatory)]
        [string]$SetupFile,

        [Parameter(Mandatory)]
        [string]$OutputFolder,

        [string]$ToolPath,

        [string]$PackageName,

        [string]$DownloadTag = 'v1.8.6',

        [switch]$AllowDownload,

        [switch]$Overwrite
    )

    # Quotes a path for the command line without a trailing separator
    function ConvertTo-ToolArgument {
        param ([string]$Path)
        $Trimmed = $Path.TrimEnd('\', '/')
        if ($Trimmed -match '^[A-Za-z]:$' -or $Trimmed -eq '') {
            $Trimmed = "$Trimmed\."
        }
        '"' + $Trimmed + '"'
    }

    #region tool
    if ($ToolPath) {
        if (-not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
            throw "IntuneWinAppUtil.exe was not found at '$ToolPath'."
        }
    }
    else {
        $ToolPath = Get-IntuneWinAppUtilPath
        if (-not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
            $ToolFolder = Split-Path -Path $ToolPath -Parent
            if (-not $AllowDownload -and -not (Confirm-ToolDownload -Folder $ToolFolder)) {
                throw "IntuneWinAppUtil.exe is required to create .intunewin packages and was not downloaded. Run 'Get-IntunePackagingTool -Path `"$ToolFolder`"', or use -AllowDownload."
            }
            Write-Verbose "Downloading IntuneWinAppUtil.exe $DownloadTag to '$ToolFolder'."
            $ToolPath = (Get-IntunePackagingTool -Path $ToolFolder -DownloadTag $DownloadTag -Force -ErrorAction Stop).FullName
        }
    }
    #endregion tool

    #region paths
    $SourceFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SourceFolder)
    $OutputFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)
    if (-not [System.IO.Path]::IsPathRooted($SetupFile)) {
        $SetupFile = Join-Path -Path $SourceFullPath -ChildPath $SetupFile
    }
    $SetupFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SetupFile)
    foreach ($Folder in $SourceFullPath, $OutputFullPath) {
        if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
            throw "The folder '$Folder' does not exist."
        }
    }
    if (-not (Test-Path -LiteralPath $SetupFullPath -PathType Leaf)) {
        throw "The setup file '$SetupFullPath' does not exist."
    }

    $ToolOutput = Join-Path -Path $OutputFullPath -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFullPath)).intunewin"
    $PackagePath = $ToolOutput
    if (-not [string]::IsNullOrEmpty($PackageName)) {
        Assert-SafePathSegment -Name $PackageName -ParameterName 'PackageName' -AllowWildcard
        $PackagePath = Join-Path -Path $OutputFullPath -ChildPath "$PackageName.intunewin"
    }
    foreach ($File in @($PackagePath, $ToolOutput) | Select-Object -Unique) {
        if (Test-Path -LiteralPath $File) {
            if (-not $Overwrite) {
                throw "The package '$File' already exists. Delete it or allow it to be overwritten."
            }
            Remove-Item -LiteralPath $File -Force -ErrorAction Stop
        }
    }
    #endregion paths

    $Arguments = '-c {0} -s {1} -o {2} -q' -f (ConvertTo-ToolArgument -Path $SourceFullPath), (ConvertTo-ToolArgument -Path $SetupFullPath), (ConvertTo-ToolArgument -Path $OutputFullPath)
    Write-Verbose "Running $ToolPath $Arguments"
    $Result = Invoke-Executable -FilePath $ToolPath -Arguments $Arguments -ErrorAction Stop
    if ($Result.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $ToolOutput -PathType Leaf)) {
        $Details = (@($Result.StandardError, $Result.StandardOutput) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
        throw "IntuneWinAppUtil.exe did not create '$ToolOutput' (exit code $($Result.ExitCode)). $Details".TrimEnd()
    }
    if ($ToolOutput -ne $PackagePath) {
        Move-Item -LiteralPath $ToolOutput -Destination $PackagePath -Force -ErrorAction Stop
    }
    Get-Item -LiteralPath $PackagePath
}
