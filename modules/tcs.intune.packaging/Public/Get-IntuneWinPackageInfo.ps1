function Get-IntuneWinPackageInfo {
    <#
    .SYNOPSIS
        Reads the metadata of a .intunewin package.

    .DESCRIPTION
        The Get-IntuneWinPackageInfo function opens a .intunewin file (a zip archive) and reads
        Metadata/Detection.xml, which IntuneWinAppUtil.exe writes: the setup file, the size of the
        content before and after encryption, the tool version and, for MSI setup files, the MSI
        details. It works on every platform; the package is not extracted.

        The encryption keys in Detection.xml are not returned.

    .PARAMETER Path
        The path to the .intunewin file. Accepts pipeline input (for example from Get-ChildItem).

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Path, Name, FileName, SetupFile, UnencryptedContentSize, EncryptedContentSize, ToolVersion and
        MsiInfo ($null for other setup files).

    .EXAMPLE
        Get-IntuneWinPackageInfo -Path .\setup.intunewin

        Shows the setup file and content sizes of setup.intunewin.

    .EXAMPLE
        Get-ChildItem -Path C:\Packages -Filter *.intunewin | Get-IntuneWinPackageInfo | Format-Table SetupFile, UnencryptedContentSize

        Lists the setup file of every package in C:\Packages.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    begin {
        $telemetry = Start-TcsTelemetry
        $lastError = $null
    }
    process {
        $completed = $false
        try {
            $Info = Read-IntuneWinPackage -Path $Path -ErrorAction Stop
            [PSCustomObject]@{
                Path                   = (Resolve-Path -LiteralPath $Path).ProviderPath
                Name                   = $Info.Name
                FileName               = $Info.FileName
                SetupFile              = $Info.SetupFile
                UnencryptedContentSize = $Info.UnencryptedContentSize
                EncryptedContentSize   = $Info.EncryptedContentSize
                ToolVersion            = $Info.ToolVersion
                MsiInfo                = $Info.MsiInfo
            }
            $completed = $true
        }
        catch {
            $lastError = $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
        finally {
            if (-not $completed) {
                Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
            }
        }
    }
    end {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
    }
}
