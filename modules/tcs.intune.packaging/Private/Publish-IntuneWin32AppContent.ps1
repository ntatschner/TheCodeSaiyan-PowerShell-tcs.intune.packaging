function Publish-IntuneWin32AppContent {
    <#
    .SYNOPSIS
        Uploads the content of a .intunewin package to an existing Win32 app and commits it.

    .DESCRIPTION
        Microsoft Graph v1.0 flow for Win32 app content:
          1. POST mobileApps/{id}/microsoft.graph.win32LobApp/contentVersions
             (https://learn.microsoft.com/graph/api/intune-apps-mobileappcontent-create)
          2. POST .../contentVersions/{id}/files with name, size, sizeEncrypted, manifest and isDependency
             (https://learn.microsoft.com/graph/api/intune-apps-mobileappcontentfile-create)
          3. Wait for uploadState azureStorageUriRequestSuccess, then upload the encrypted content to
             azureStorageUri in blocks (Send-IntuneContentFile)
          4. POST .../files/{id}/commit with fileEncryptionInfo from Detection.xml
             (https://learn.microsoft.com/graph/api/intune-apps-mobileappcontentfile-commit)
          5. Wait for uploadState commitFileSuccess, then PATCH the app with committedContentVersion
             (https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-update)
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$IntuneWinPath,

        [int]$PollIntervalSeconds = 5,

        [int]$TimeoutSeconds = 600
    )

    $AppUri = "v1.0/deviceAppManagement/mobileApps/$AppId"
    $EncryptedPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "IntunePackage-$([guid]::NewGuid().ToString('N')).bin"
    try {
        $Package = Get-IntuneWinPackageInfo -Path $IntuneWinPath -ExtractTo $EncryptedPath -ErrorAction Stop

        Write-Verbose "Creating a content version for app $AppId."
        $ContentVersion = Invoke-MgGraphRequest -Method POST -Uri "$AppUri/microsoft.graph.win32LobApp/contentVersions" -Body '{}' -ContentType 'application/json' -OutputType PSObject -ErrorAction Stop
        $FilesUri = "$AppUri/microsoft.graph.win32LobApp/contentVersions/$($ContentVersion.id)/files"

        $FileBody = [ordered]@{
            '@odata.type' = '#microsoft.graph.mobileAppContentFile'
            name          = $Package.FileName
            size          = $Package.UnencryptedContentSize
            sizeEncrypted = $Package.EncryptedContentSize
            manifest      = $null
            isDependency  = $false
        } | ConvertTo-Json -Compress
        Write-Verbose "Creating the content file $($Package.FileName)."
        $File = Invoke-MgGraphRequest -Method POST -Uri $FilesUri -Body $FileBody -ContentType 'application/json' -OutputType PSObject -ErrorAction Stop
        $FileUri = "$FilesUri/$($File.id)"

        $File = Wait-IntuneContentFileState -FileUri $FileUri -State azureStorageUriRequestSuccess -PollIntervalSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds
        Send-IntuneContentFile -Path $EncryptedPath -SasUri $File.azureStorageUri -FileUri $FileUri -PollIntervalSeconds $PollIntervalSeconds

        Write-Verbose 'Committing the content file.'
        $CommitBody = @{ fileEncryptionInfo = $Package.EncryptionInfo } | ConvertTo-Json -Depth 5 -Compress
        $null = Invoke-MgGraphRequest -Method POST -Uri "$FileUri/commit" -Body $CommitBody -ContentType 'application/json' -ErrorAction Stop
        $null = Wait-IntuneContentFileState -FileUri $FileUri -State commitFileSuccess -PollIntervalSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds

        Write-Verbose "Setting committedContentVersion to $($ContentVersion.id)."
        $PatchBody = @{
            '@odata.type'           = '#microsoft.graph.win32LobApp'
            committedContentVersion = [string]$ContentVersion.id
        } | ConvertTo-Json -Compress
        $null = Invoke-MgGraphRequest -Method PATCH -Uri $AppUri -Body $PatchBody -ContentType 'application/json' -ErrorAction Stop
        [string]$ContentVersion.id
    }
    finally {
        if (Test-Path -Path $EncryptedPath) {
            Remove-Item -Path $EncryptedPath -Force -ErrorAction SilentlyContinue
        }
    }
}
