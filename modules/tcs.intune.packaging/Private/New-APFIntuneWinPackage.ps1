function New-APFIntuneWinPackage {
    <#
    .SYNOPSIS
        Wraps an APF package folder into a .intunewin file with IntuneWinAppUtil.exe.

    .DESCRIPTION
        Shared by New-APFDeployment and New-APFConfigDeployment. Downloads IntuneWinAppUtil.exe to the
        per-user tool folder when it is missing (after confirmation), runs it and returns the .intunewin
        file. When PackageName is given the output is renamed to "<PackageName>.intunewin".
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [string]$SourceFolder,

        [Parameter(Mandatory)]
        [string]$SetupFile,

        [Parameter(Mandatory)]
        [string]$OutputFolder,

        [string]$PackageName
    )

    $ToolPath = Get-IntuneWinAppUtilPath
    if (-not (Test-Path -Path $ToolPath -PathType Leaf)) {
        $ToolFolder = Split-Path -Path $ToolPath -Parent
        if ($PSCmdlet.ShouldContinue("IntuneWinAppUtil.exe was not found in '$ToolFolder'. Download it from GitHub now?", 'Download IntuneWinAppUtil.exe')) {
            $null = Get-IntunePackagingTool -Path $ToolFolder -Force -ErrorAction Stop
        }
        else {
            throw "IntuneWinAppUtil.exe is required to create .intunewin packages. Run 'Get-IntunePackagingTool -Path `"$ToolFolder`"' to download it."
        }
    }

    $ToolOutput = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFile)).intunewin"
    if ([string]::IsNullOrEmpty($PackageName)) {
        $PackagePath = $ToolOutput
    }
    else {
        $PackagePath = Join-Path -Path $OutputFolder -ChildPath "$PackageName.intunewin"
    }

    if (Test-Path -Path $PackagePath -PathType Leaf) {
        if ($PSCmdlet.ShouldContinue("Overwrite the existing package '$PackagePath'?", 'Confirm overwrite')) {
            Remove-Item -Path $PackagePath -Force -ErrorAction Stop
        }
        else {
            throw "The package '$PackagePath' already exists. Delete it or choose a different destination folder."
        }
    }

    if (-not $PSCmdlet.ShouldProcess($PackagePath, 'Create .intunewin package')) {
        return
    }
    $Result = Invoke-Executable -FilePath $ToolPath -Arguments "-c `"$SourceFolder`" -s `"$SetupFile`" -o `"$OutputFolder`" -q"
    if ($Result.ExitCode -ne 0 -or -not (Test-Path -Path $ToolOutput -PathType Leaf)) {
        throw "IntuneWinAppUtil.exe did not create '$ToolOutput' (exit code $($Result.ExitCode)). $($Result.StandardError)"
    }
    if ($ToolOutput -ne $PackagePath) {
        Move-Item -Path $ToolOutput -Destination $PackagePath -Force -ErrorAction Stop
    }
    Get-Item -LiteralPath $PackagePath
}
