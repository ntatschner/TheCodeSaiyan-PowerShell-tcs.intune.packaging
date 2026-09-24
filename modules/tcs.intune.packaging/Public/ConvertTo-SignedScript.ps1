function ConvertTo-SignedScript {
    <#
    .SYNOPSIS
        Signs PowerShell script files with a PFX certificate.

    .DESCRIPTION
        The ConvertTo-SignedScript function signs PowerShell files (.ps1, .psm1, .psd1) with the code
        signing certificate in a PFX file, using Set-AuthenticodeSignature and a DigiCert timestamp.
        Each file is signed once; a file that fails is reported and the others are still signed.

        This function needs Windows (Set-AuthenticodeSignature is only available there).

    .PARAMETER Path
        The path to one or more PowerShell script files to sign. Accepts pipeline input.
        The files must exist, have a .ps1, .psm1 or .psd1 extension and not be empty.

    .PARAMETER CertificateFile
        The path to the PFX certificate file used for signing.

    .PARAMETER Password
        The password for the PFX certificate file as a SecureString.

    .PARAMETER TimestampServer
        The URL of the timestamp server. Default is http://timestamp.digicert.com.

    .OUTPUTS
        System.Management.Automation.Signature
        The signature result for each file, as returned by Set-AuthenticodeSignature.

    .EXAMPLE
        ConvertTo-SignedScript -Path "C:\Scripts\MyScript.ps1" -CertificateFile "C:\Certs\MyCert.pfx" -Password (Read-Host -AsSecureString -Prompt 'PFX password')

        Signs the specified PowerShell script with the provided certificate.

    .EXAMPLE
        Get-ChildItem -Path "C:\Scripts\*.ps1" | ConvertTo-SignedScript -CertificateFile "C:\Certs\MyCert.pfx" -Password $securePass

        Signs all PowerShell scripts in the specified directory using pipeline input.

    .NOTES
        The certificate must be valid for code signing and trusted on the system where the scripts will run.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Management.Automation.Signature])]
    param (
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    throw "File not found: $_"
                }
                if ([System.IO.Path]::GetExtension($_) -notin @('.ps1', '.psm1', '.psd1')) {
                    throw "File must be a PowerShell script (.ps1, .psm1 or .psd1): $_"
                }
                if ((Get-Item -Path $_).Length -eq 0) {
                    throw "File is empty: $_"
                }
                $true
            })]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string[]]
        $Path,

        [parameter(Mandatory)]
        [ValidateScript({
                if ([System.IO.Path]::GetExtension($_) -ne '.pfx') {
                    throw "File must be a PFX Certificate File: $_"
                }
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    throw "File not found: $_"
                }
                if ((Get-Item -Path $_).Length -eq 0) {
                    throw "File is empty: $_"
                }
                $true
            })]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateFile,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [securestring]
        $Password,

        [ValidateNotNullOrEmpty()]
        [string]
        $TimestampServer = 'http://timestamp.digicert.com'
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
        try {
            if (-not (Get-Command -Name 'Set-AuthenticodeSignature' -ErrorAction SilentlyContinue)) {
                throw 'Set-AuthenticodeSignature is not available. ConvertTo-SignedScript needs Windows.'
            }
            try {
                # Get-PfxCertificate -Password does not exist in Windows PowerShell 5.1, so load the PFX directly
                $CertificateFullPath = (Resolve-Path -Path $CertificateFile -ErrorAction Stop).ProviderPath
                $CertificateObject = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $CertificateFullPath, $Password
            }
            catch {
                throw "Failed to load certificate '$CertificateFile': $($_.Exception.Message)"
            }
            if (-not $CertificateObject.HasPrivateKey) {
                throw "The certificate in '$CertificateFile' has no private key and cannot be used for signing."
            }
        }
        catch {
            $TelemetryFailed = $true
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
    process {
        try {
            foreach ($Script in $Path) {
                if (-not $PSCmdlet.ShouldProcess($Script, 'Sign script')) {
                    continue
                }
                try {
                    Set-AuthenticodeSignature -Certificate $CertificateObject -TimestampServer $TimestampServer -FilePath $Script -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Failed to sign script '$Script': $($_.Exception.Message)"
                }
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
