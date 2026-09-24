function New-APFIntuneWinPackage {
    <#
    .SYNOPSIS
        Wraps an APF package folder into a .intunewin file with IntuneWinAppUtil.exe.

    .DESCRIPTION
        Shared by New-APFDeployment and New-APFConfigDeployment. Asks before an existing package is
        replaced, then runs Invoke-IntuneWinAppUtil (which asks before IntuneWinAppUtil.exe is
        downloaded) and returns the .intunewin file. When PackageName is given the output is renamed
        to "<PackageName>.intunewin".
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

    if ([string]::IsNullOrEmpty($PackageName)) {
        $PackagePath = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFile)).intunewin"
    }
    else {
        $PackagePath = Join-Path -Path $OutputFolder -ChildPath "$PackageName.intunewin"
    }

    if (Test-Path -LiteralPath $PackagePath -PathType Leaf) {
        if (-not $PSCmdlet.ShouldContinue("Overwrite the existing package '$PackagePath'?", 'Confirm overwrite')) {
            throw "The package '$PackagePath' already exists. Delete it or choose a different destination folder."
        }
    }

    if (-not $PSCmdlet.ShouldProcess($PackagePath, 'Create .intunewin package')) {
        return
    }
    Invoke-IntuneWinAppUtil -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -PackageName $PackageName -Overwrite
}
