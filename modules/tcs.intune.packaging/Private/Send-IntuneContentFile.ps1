function Send-IntuneContentFile {
    <#
    .SYNOPSIS
        Uploads a file to the Azure Storage SAS URI of a Win32 app content file in blocks.

    .DESCRIPTION
        Uses the Blob service Put Block (PUT <sas>&comp=block&blockid=<id>) and Put Block List
        (PUT <sas>&comp=blocklist) operations:
        https://learn.microsoft.com/rest/api/storageservices/put-block
        https://learn.microsoft.com/rest/api/storageservices/put-block-list
        Block IDs are Base64 strings of equal length. When RenewAfterSeconds have passed, the SAS URI
        is renewed with the renewUpload action
        (https://learn.microsoft.com/graph/api/intune-apps-mobileappcontentfile-renewupload).
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$SasUri,

        [Parameter(Mandatory)]
        [string]$FileUri,

        [ValidateRange(1, 100)]
        [int]$ChunkSizeMB = 6,

        [int]$RenewAfterSeconds = 420,

        [int]$PollIntervalSeconds = 5
    )

    $ChunkSize = $ChunkSizeMB * 1024 * 1024
    $BlockIds = New-Object -TypeName System.Collections.Generic.List[string]
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    $Stream = [System.IO.File]::OpenRead($Path)
    try {
        $Buffer = New-Object -TypeName byte[] -ArgumentList $ChunkSize
        $Index = 0
        while (($Read = $Stream.Read($Buffer, 0, $ChunkSize)) -gt 0) {
            if ($Timer.Elapsed.TotalSeconds -ge $RenewAfterSeconds) {
                Write-Verbose 'Renewing the Azure Storage SAS URI.'
                $null = Invoke-MgGraphRequest -Method POST -Uri "$FileUri/renewUpload" -ErrorAction Stop
                $SasUri = (Wait-IntuneContentFileState -FileUri $FileUri -State azureStorageUriRenewalSuccess -PollIntervalSeconds $PollIntervalSeconds).azureStorageUri
                $Timer.Restart()
            }
            if ($Read -eq $ChunkSize) {
                $Chunk = $Buffer
            }
            else {
                $Chunk = New-Object -TypeName byte[] -ArgumentList $Read
                [System.Array]::Copy($Buffer, $Chunk, $Read)
            }
            $BlockId = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Index.ToString('000000')))
            Write-Verbose "Uploading block $Index ($Read bytes)."
            $null = Invoke-WebRequest -Method Put -Uri "$SasUri&comp=block&blockid=$([System.Uri]::EscapeDataString($BlockId))" -Body $Chunk -ContentType 'application/octet-stream' -UseBasicParsing -ErrorAction Stop
            $BlockIds.Add($BlockId)
            $Index++
        }
    }
    finally {
        $Stream.Dispose()
    }

    $BlockList = '<?xml version="1.0" encoding="utf-8"?><BlockList>' + (($BlockIds | ForEach-Object { "<Latest>$_</Latest>" }) -join '') + '</BlockList>'
    $null = Invoke-WebRequest -Method Put -Uri "$SasUri&comp=blocklist" -Body $BlockList -ContentType 'application/xml' -UseBasicParsing -ErrorAction Stop
}
