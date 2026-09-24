function New-PackageJSON {
    <#
    .SYNOPSIS
        Creates a package JSON metadata file for an application deployment.

    .DESCRIPTION
        The New-PackageJSON function writes a JSON file with package metadata (package name, version,
        description, author, main installer file name and a comma-separated list of the names of all
        items in the source directory) to "package-<PackageName>-v<Version>.json" in the source directory.
        An existing metadata file with the same name is overwritten and is not listed in AllFiles.

    .PARAMETER PackageName
        The name of the application package.

    .PARAMETER Version
        The version number of the package.

    .PARAMETER Description
        A description of the package and its contents.

    .PARAMETER Author
        The author or creator of the package.

    .PARAMETER SourceDirectory
        The directory that contains the application files. The JSON file is written here.

    .PARAMETER MainInstaller
        The file name of the main installer executable or MSI file.

    .OUTPUTS
        System.IO.FileInfo
        The JSON file that was written.

    .EXAMPLE
        New-PackageJSON -PackageName "MyApp" -Version "1.0.0" -Description "My Application" -Author "IT Team" -SourceDirectory "C:\Apps\MyApp" -MainInstaller "setup.exe"

        Creates C:\Apps\MyApp\package-MyApp-v1.0.0.json.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [string]
        $PackageName,

        [Parameter(Mandatory)]
        [string]
        $Version,

        [Parameter(Mandatory)]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [string]
        $Author,

        [parameter(Mandatory)]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Container)) {
                    throw "The directory '$_' does not exist."
                }
                $true
            })]
        [string]
        $SourceDirectory,

        [Parameter(Mandatory)]
        [string]
        $MainInstaller
    )

    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $JSONFileName = "package-$($PackageName)-v$($Version).json"
        $PackageJSONPath = Join-Path -Path $SourceDirectory -ChildPath $JSONFileName
        $AllFiles = @(Get-ChildItem -Path $SourceDirectory -Recurse | Where-Object { $_.Name -ne $JSONFileName } | ForEach-Object { $_.Name })

        $PackageJSON = [ordered]@{
            PackageName   = $PackageName
            Version       = $Version
            Description   = $Description
            Author        = $Author
            MainInstaller = $MainInstaller
            AllFiles      = $AllFiles -join ','
        }

        if ($PSCmdlet.ShouldProcess($PackageJSONPath, 'Write package JSON')) {
            try {
                $PackageJSON | ConvertTo-Json | Set-Content -Path $PackageJSONPath -Encoding UTF8 -ErrorAction Stop
            }
            catch {
                throw "Failed to create $($PackageJSONPath): $($_.Exception.Message)"
            }
            Get-Item -LiteralPath $PackageJSONPath
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
