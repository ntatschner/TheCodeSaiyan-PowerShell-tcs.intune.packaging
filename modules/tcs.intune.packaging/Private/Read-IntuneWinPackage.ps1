function Read-IntuneWinPackage {
    <#
    .SYNOPSIS
        Reads the metadata of a .intunewin package and extracts its encrypted content.

    .DESCRIPTION
        A .intunewin file is a zip archive with two folders: Contents, which holds the encrypted
        package (IntunePackage.intunewin), and Metadata, which holds Detection.xml with the file
        encryption information
        (https://learn.microsoft.com/troubleshoot/mem/intune/app-management/develop-deliver-working-win32-app-via-intune).
        This function reads Detection.xml and, with -ExtractTo, copies the encrypted package to a file.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$ExtractTo
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    $FullPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $Archive = [System.IO.Compression.ZipFile]::OpenRead($FullPath)
    try {
        $Entries = @($Archive.Entries)
        $DetectionEntry = $Entries | Where-Object { $_.FullName.Replace('\', '/') -like '*Metadata/Detection.xml' } | Select-Object -First 1
        $ContentEntry = $Entries | Where-Object { $_.FullName.Replace('\', '/') -like '*Contents/*.intunewin' } | Select-Object -First 1
        if (-not $DetectionEntry -or -not $ContentEntry) {
            throw "'$Path' is not a .intunewin package: Metadata/Detection.xml or the encrypted content in Contents/ is missing."
        }

        $Reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $DetectionEntry.Open()
        try {
            [xml]$Detection = $Reader.ReadToEnd()
        }
        finally {
            $Reader.Dispose()
        }
        $Info = $Detection.ApplicationInfo
        $Encryption = $Info.EncryptionInfo
        if (-not $Info -or -not $Encryption) {
            throw "Detection.xml in '$Path' does not contain ApplicationInfo/EncryptionInfo."
        }

        $EncryptedPath = $null
        if ($ExtractTo) {
            $EncryptedPath = $ExtractTo
            $Source = $ContentEntry.Open()
            try {
                $Target = [System.IO.File]::Create($EncryptedPath)
                try {
                    $Source.CopyTo($Target)
                }
                finally {
                    $Target.Dispose()
                }
            }
            finally {
                $Source.Dispose()
            }
        }

        [PSCustomObject]@{
            Name                   = [string]$Info.Name
            FileName               = [string]$Info.FileName
            SetupFile              = [string]$Info.SetupFile
            UnencryptedContentSize = [int64]$Info.UnencryptedContentSize
            EncryptedContentSize   = [int64]$ContentEntry.Length
            EncryptedContentPath   = $EncryptedPath
            EncryptionInfo         = [ordered]@{
                encryptionKey        = [string]$Encryption.EncryptionKey
                macKey               = [string]$Encryption.MacKey
                initializationVector = [string]$Encryption.InitializationVector
                mac                  = [string]$Encryption.Mac
                profileIdentifier    = [string]$Encryption.ProfileIdentifier
                fileDigest           = [string]$Encryption.FileDigest
                fileDigestAlgorithm  = [string]$Encryption.FileDigestAlgorithm
            }
        }
    }
    finally {
        $Archive.Dispose()
    }
}
