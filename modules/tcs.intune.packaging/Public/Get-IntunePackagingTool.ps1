function Get-IntunePackagingTool {
    <#
    .SYNOPSIS
        Downloads the Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe).

    .DESCRIPTION
        The Get-IntunePackagingTool function downloads a release of the Microsoft Win32 Content Prep Tool
        from GitHub (github.com/microsoft/Microsoft-Win32-Content-Prep-Tool), extracts it to a temporary
        folder and copies IntuneWinAppUtil.exe to Path. The downloaded archive and the extracted files
        are removed afterwards.

        By default the latest release is downloaded. Use DownloadTag to pin a release, or DownloadUrl to
        download a specific zip file.

        The downloaded IntuneWinAppUtil.exe is verified before it is copied to Path, and refused when a
        check fails:
          - On Windows it must have a valid Authenticode signature from Microsoft Corporation
            (Get-AuthenticodeSignature: Status Valid and O=Microsoft Corporation in the signer subject).
          - With ExpectedSha256 its SHA256 hash must match. Where Authenticode signatures cannot be
            checked (PowerShell on Linux or macOS), ExpectedSha256 is required.

    .PARAMETER Path
        The folder that IntuneWinAppUtil.exe is copied to. It is created when it does not exist.

    .PARAMETER DownloadTag
        The release tag to download, for example 'v1.8.6'.

    .PARAMETER DownloadUrl
        The URL of a zip file that contains IntuneWinAppUtil.exe. Used instead of the GitHub release
        archive.

    .PARAMETER ExpectedSha256
        The expected SHA256 hash (64 hexadecimal characters) of IntuneWinAppUtil.exe. When given, the
        downloaded file must match it.

    .PARAMETER Force
        Overwrites IntuneWinAppUtil.exe when it already exists in Path.

    .OUTPUTS
        System.IO.FileInfo
        The copied IntuneWinAppUtil.exe file.

    .EXAMPLE
        Get-IntunePackagingTool -Path "C:\Tools"

        Downloads the latest release and copies IntuneWinAppUtil.exe to C:\Tools.

    .EXAMPLE
        Get-IntunePackagingTool -Path "C:\Tools" -DownloadTag 'v1.8.6' -Force

        Downloads release v1.8.6 and overwrites an existing C:\Tools\IntuneWinAppUtil.exe.

    .EXAMPLE
        Get-IntunePackagingTool -Path "C:\Tools" -DownloadTag 'v1.8.6' -ExpectedSha256 '<sha256 of IntuneWinAppUtil.exe>'

        Downloads release v1.8.6 and only keeps IntuneWinAppUtil.exe when its hash matches.

    .LINK
        https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
    #>
    [CmdletBinding(DefaultParameterSetName = 'Latest')]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'DownloadTag')]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadTag,

        [Parameter(Mandatory = $true, ParameterSetName = 'DownloadUrl')]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadUrl,

        [ValidatePattern('^[0-9A-Fa-f]{64}$')]
        [string]$ExpectedSha256,

        [switch]$Force
    )
    $TelemetryArgs = @{
        ModuleName    = $MyInvocation.MyCommand.Module.Name
        ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
        CommandName   = $MyInvocation.MyCommand.Name
        ExecutionID   = [guid]::NewGuid().ToString()
    }
    Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
    try {
        $RepositoryUrl = 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool'
        switch ($PSCmdlet.ParameterSetName) {
            'DownloadTag' {
                Write-Verbose "Using the specified download tag '$DownloadTag'."
                $DownloadUrl = "$RepositoryUrl/archive/refs/tags/$DownloadTag.zip"
            }
            'Latest' {
                Write-Verbose 'Getting the latest release of the Microsoft Win32 Content Prep Tool.'
                try {
                    $LatestRelease = Invoke-RestMethod -Uri "$RepositoryUrl/releases/latest" -Headers @{ Accept = 'application/json' } -UseBasicParsing -ErrorAction Stop
                }
                catch {
                    throw "Failed to get the latest release of the Microsoft Win32 Content Prep Tool: $($_.Exception.Message)"
                }
                if ([string]::IsNullOrEmpty($LatestRelease.tag_name)) {
                    throw 'Failed to get the latest release of the Microsoft Win32 Content Prep Tool: the response did not contain a tag name.'
                }
                Write-Verbose "Latest tag: $($LatestRelease.tag_name)"
                $DownloadUrl = "$RepositoryUrl/archive/refs/tags/$($LatestRelease.tag_name).zip"
            }
        }

        $WorkFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "IntuneWinAppUtil-$([guid]::NewGuid().ToString('N'))"
        $DownloadPath = Join-Path -Path $WorkFolder -ChildPath 'IntuneWinAppUtil.zip'
        $ExtractionPath = Join-Path -Path $WorkFolder -ChildPath 'extracted'
        try {
            $null = New-Item -Path $WorkFolder -ItemType Directory -Force -ErrorAction Stop

            Write-Verbose "Downloading '$DownloadUrl' to '$DownloadPath'."
            try {
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                throw "Failed to download the Microsoft Win32 Content Prep Tool from $($DownloadUrl): $($_.Exception.Message)"
            }

            Write-Verbose "Extracting '$DownloadPath'."
            Expand-Archive -Path $DownloadPath -DestinationPath $ExtractionPath -Force -ErrorAction Stop

            $ToolFile = Get-ChildItem -Path $ExtractionPath -Recurse -File -Filter 'IntuneWinAppUtil.exe' -ErrorAction Stop | Select-Object -First 1
            if (-not $ToolFile) {
                throw "IntuneWinAppUtil.exe was not found in the archive downloaded from $DownloadUrl."
            }
            # Refuse a tool that is not signed by Microsoft or does not match the expected hash
            Assert-IntuneWinAppUtilFile -Path $ToolFile.FullName -ExpectedSha256 $ExpectedSha256

            if (-not (Test-Path -Path $Path -PathType Container)) {
                $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            }
            $Destination = Join-Path -Path $Path -ChildPath $ToolFile.Name
            if ((Test-Path -Path $Destination -PathType Leaf) -and -not $Force) {
                throw "'$Destination' already exists. Use -Force to overwrite it."
            }
            Copy-Item -LiteralPath $ToolFile.FullName -Destination $Destination -Force -ErrorAction Stop
            Write-Verbose "IntuneWinAppUtil.exe has been copied to '$Path'."
            Get-Item -LiteralPath $Destination
        }
        finally {
            if (Test-Path -LiteralPath $WorkFolder) {
                Remove-Item -LiteralPath $WorkFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage End
    }
    catch {
        Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
        throw
    }
}
