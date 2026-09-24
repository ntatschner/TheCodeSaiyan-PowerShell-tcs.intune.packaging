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
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        $TelemetryFailed = $false
    }
    process {
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
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
