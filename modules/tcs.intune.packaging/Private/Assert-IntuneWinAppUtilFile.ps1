function Assert-IntuneWinAppUtilFile {
    <#
    .SYNOPSIS
        Throws unless a downloaded IntuneWinAppUtil.exe can be trusted.

    .DESCRIPTION
        With ExpectedSha256 the SHA256 hash of the file must match. On Windows the file must also
        carry a valid Authenticode signature whose signer certificate subject has
        O=Microsoft Corporation (Get-AuthenticodeSignature). Where Get-AuthenticodeSignature is not
        available (PowerShell on Linux or macOS) the file is only accepted with a matching
        ExpectedSha256.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$ExpectedSha256
    )

    if ($ExpectedSha256) {
        $Hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($Hash -ne $ExpectedSha256.ToUpperInvariant()) {
            throw "The SHA256 hash of the downloaded IntuneWinAppUtil.exe ($Hash) does not match the expected hash $($ExpectedSha256.ToUpperInvariant())."
        }
        Write-Verbose 'The SHA256 hash of IntuneWinAppUtil.exe matches the expected hash.'
    }

    if (Get-Command -Name 'Get-AuthenticodeSignature' -ErrorAction SilentlyContinue) {
        $Signature = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        if ([string]$Signature.Status -ne 'Valid') {
            throw "The downloaded IntuneWinAppUtil.exe does not have a valid Authenticode signature (status '$($Signature.Status)'): $($Signature.StatusMessage)"
        }
        $Subject = [string]$Signature.SignerCertificate.Subject
        if ($Subject -notmatch '(^|,\s*)O=Microsoft Corporation(\s*,|$)') {
            throw "The downloaded IntuneWinAppUtil.exe is signed by '$Subject', not by Microsoft Corporation."
        }
        Write-Verbose "IntuneWinAppUtil.exe has a valid Authenticode signature from '$Subject'."
    }
    elseif (-not $ExpectedSha256) {
        throw 'The Authenticode signature of IntuneWinAppUtil.exe cannot be checked on this platform (Get-AuthenticodeSignature is not available). Pass -ExpectedSha256 to verify the download by its hash.'
    }
}
