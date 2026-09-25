function Start-DownloadFile {
    <#
    .SYNOPSIS
        Downloads a file from a URL and saves it in a folder.

    .DESCRIPTION
        The Start-DownloadFile function downloads the file at URL and saves it as Name in the folder Path.
        The folder is created when it does not exist. Download progress is shown by Invoke-WebRequest.
        A failed download throws a terminating error and no partial file is left behind.

        Deprecated: no other command in this module uses Start-DownloadFile, and it may be removed in a
        future version. Use Invoke-WebRequest -OutFile instead. A deprecation warning is written each
        time it runs.

    .PARAMETER URL
        The URL of the file to download.

    .PARAMETER Path
        The folder where the file is saved. It is created when it does not exist.

    .PARAMETER Name
        The file name to save the download as, including the file extension.

    .OUTPUTS
        None

    .EXAMPLE
        Start-DownloadFile -URL 'https://example.com/setup.msi' -Path 'C:\Temp\Downloads' -Name 'setup.msi'

        Downloads setup.msi to C:\Temp\Downloads\setup.msi.

    .NOTES
        Originally based on a function by Nickolaj Andersen (@NickolajA).
        Since 0.3.0 the download uses Invoke-WebRequest instead of System.Net.WebClient events and no
        longer creates global variables.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [parameter(Mandatory = $true, HelpMessage = "URL for the file to be downloaded.")]
        [ValidateNotNullOrEmpty()]
        [string]$URL,

        [parameter(Mandatory = $true, HelpMessage = "Folder where the file will be downloaded.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [parameter(Mandatory = $true, HelpMessage = "Name of the file including file extension.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name
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
        Write-Warning 'Start-DownloadFile is deprecated and may be removed in a future version. Use Invoke-WebRequest -OutFile instead.'
    }
    process {
        try {
            $Destination = Join-Path -Path $Path -ChildPath $Name
            if (-not $PSCmdlet.ShouldProcess($Destination, "Download $URL")) {
                return
            }
            if (-not (Test-Path -Path $Path -PathType Container)) {
                $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            }
            try {
                Invoke-WebRequest -Uri $URL -OutFile $Destination -UseBasicParsing -ErrorAction Stop
            }
            catch {
                if (Test-Path -Path $Destination -PathType Leaf) {
                    Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
                }
                throw "Failed to download '$URL' to '$Destination': $($_.Exception.Message)"
            }
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            throw
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
