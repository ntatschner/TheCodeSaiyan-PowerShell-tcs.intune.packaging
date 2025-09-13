#Downloads the Intune Content Prep Tools from the Microsoft Download Center and extracts the contents to the specified path.
function Get-IntunePackagingTool {
    <#
.SYNOPSIS
Downloads the Intune Content Prep Tools from the Microsoft Download Center and extracts the contents to the specified path.

.DESCRIPTION
The Get-IntunePackagingTool function downloads the Intune Content Prep Tools from the Microsoft Download Center and extracts the contents to the specified path.

.PARAMETER Path
The path to extract the Intune Content Prep Tools to.

.EXAMPLE
Get-IntunePackagingTool -Path "C:\path\to\extract\to"

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(ParameterSetName = 'DownloadTag')]
        [string]$DownloadTag,
        [string]$DownloadUrl,
        [switch]$Force

    )
    begin {
        if ($PSBoundParameters.ContainsKey('Debug')) {
            $DebugPreference = 'Inquire'
        }
        else {
            $DebugPreference = 'SilentlyContinue'
        }
        # Set the download URL and path based on the specified tag
        if ($PSCmdlet.ParameterSetName -eq 'DownloadTag') {
            Write-Verbose "Using the specified download tag '$DownloadTag'..."
            $local:DownloadUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/tags/$DownloadTag.zip"
            $local:DownloadPath = Join-Path -Path $env:TEMP -ChildPath "$DownloadTag.zip"
            $local:DownloadPathParent = Split-Path -Path $DownloadPath -Parent
        }
        if ([string]::IsNullOrEmpty($DownloadUrl) -and [string]::IsNullOrEmpty($DownloadTag)) {
            # Set the download URL and path for the latest release
            Write-Verbose "Getting the latest release of the Intune Content Prep Tools..."
            $LatestTag = $(Invoke-WebRequest -Uri "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases/latest" -Headers @{"Accept" = "application/json" } -UseBasicParsing | ConvertFrom-Json).tag_name
            Write-Debug "Latest tag: $LatestTag"
            $local:DownloadUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/tags/$LatestTag.zip"
            Write-Debug "Download URL: $DownloadUrl"
            $local:DownloadPath = Join-Path -Path $env:TEMP -ChildPath "$LatestTag.zip"
            Write-Debug "Download Path: $DownloadPath"
            $local:DownloadPathParent = Split-Path -Path $DownloadPath -Parent
        }
        else {
            # Split up provided download URL to get the file name
            $local:DownloadUrlSplit = $DownloadUrl.Split("/")[-1]
            $local:DownloadPath = Join-Path -Path $env:TEMP -ChildPath $DownloadUrlSplit
        }
    }
    process {
        try {
            # Download the Intune Content Prep Tools
            Write-Verbose "Downloading the Intune Content Prep Tools from Github;`n$DownloadUrl`nto $DownloadPath..."
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath -UseBasicParsing -ErrorAction Stop
            $local:ExtractionPath = $DownloadPath -replace (Get-item -Path $DownloadPath).Extension , ""
        }
        catch {
            Write-Error "Failed to download the Intune Content Prep Tools from $($DownloadUrl): $_"
            exit
        }
        
        try {
            # Extract the Intune Content Prep Tools
            Write-Verbose "Extracting the Intune Content Prep Tools to '$Path'..."
            Expand-Archive -Path $DownloadPath -DestinationPath $ExtractionPath -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to extract the Intune Content Prep Tools: $_"
            exit
        }

        try {
            # Copy the .exe file to the specified path
            $FileToCopy = Get-childitem -Path $ExtractionPath -Recurse -Include "*.exe"
            Copy-Item -Path $FileToCopy -Destination $Path -ErrorAction Stop
            Write-Verbose "The Intune Content Prep Tools have been extracted to '$Path'."
        }
        catch {
            Write-Error "Failed to copy the Intune Content Prep Tools: $_"
            exit
        }

        try {
            # Remove the downloaded zip file and extracted folder
            Write-Verbose "Removing the downloaded zip file."
            Remove-Item -Path $DownloadPath -Force -Confirm:$false
            Write-Verbose "Removing the extracted folder."
            Remove-Item -Path $ExtractionPath -Recurse -Force -Confirm:$false
        }
        catch {
            Write-Error "Failed to remove the downloaded zip file or the extracted folder: $_"
        }

    }
}
# SIG # Begin signature block
# MIIb+wYJKoZIhvcNAQcCoIIb7DCCG+gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAXoQl482fYXctE
# zkZN9krV08mmYVZbxK/L4dTF59AdmqCCFjkwggMsMIICFKADAgECAhBmhT86JMfH
# mUiR0ez4JrWKMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI0ludHVuZSBQb3dl
# clNoZWxsIENvZGUgU2lnbmluZyBDZXJ0MB4XDTI0MDUyOTEyMDYwM1oXDTI3MDUy
# OTEyMTYwM1owLjEsMCoGA1UEAwwjSW50dW5lIFBvd2VyU2hlbGwgQ29kZSBTaWdu
# aW5nIENlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDWg3Kh7JSY
# lfhlXejOd9V7MJl9YtntMfB2FMcfLG19tfAkcsTmgfPcIdsfEvA+29Vhnk/U6dI+
# loaBIJcgIJDNosQLe9jIc+nvUdRRXLd93BUM1Wf83+O5nPBfUivlo3ijLNz+bbKO
# blEhISUkJx7U6JEipd1EYp7Qf4gtEiuYe/4Ubz/tsgTYqRZZFGCwMfLwXq7tHokg
# 1xymns9As+RgpNtnyuAri4TUuab/pGkNrEp3pjDu0rAmlXdrgYqJedKgtHsS4qzT
# ocvQjmZDLhk6oKG2DW3nibG2eiCdT5Z1/66Kdfz8khJRuhlUq/WSafSj43BTb95n
# JfI1dod9ZuONAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUom8gX08Z97hgsB0WRxYEgKvFOOswDQYJKoZIhvcN
# AQELBQADggEBAKaWG+cjhAUW/Vv3MPFcgZNIwMYkox7lL1IE9YM6FIjOpXch8OhD
# z7f9q9NXs5OcCtxwoZh7pSk2eaHygXwa1L5HVy5/uAS/BRbCZ93XkI1/i6Mcc8H/
# /QvkawNBInZvGeXWnSYKrACpmkHO2ZxdOYyZ5+LTCo8cviNdNM8vidVzsuBfxrBU
# ug52y1Kk0iWxNm1L7IdVkfz0H/pAOM8/5Oy4kR+S4jzFn4jCacDuoAbR0O4sk5ce
# zOtXsWPMKuQujjfWb78/w/mvidgrRa1vw4/OcR5UQSq3mDVWyNiJyBuxJ44GNiwF
# jbEEiBPdyi0JsHcSL215DGHUFPn8/U4FRXIwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# wjCCBKqgAwIBAgIQBUSv85SdCDmmv9s/X+VhFjANBgkqhkiG9w0BAQsFADBjMQsw
# CQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRp
# Z2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENB
# MB4XDTIzMDcxNDAwMDAwMFoXDTM0MTAxMzIzNTk1OVowSDELMAkGA1UEBhMCVVMx
# FzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1l
# c3RhbXAgMjAyMzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKNTRYcd
# g45brD5UsyPgz5/X5dLnXaEOCdwvSKOXejsqnGfcYhVYwamTEafNqrJq3RApih5i
# Y2nTWJw1cb86l+uUUI8cIOrHmjsvlmbjaedp/lvD1isgHMGXlLSlUIHyz8sHpjBo
# yoNC2vx/CSSUpIIa2mq62DvKXd4ZGIX7ReoNYWyd/nFexAaaPPDFLnkPG2ZS48jW
# Pl/aQ9OE9dDH9kgtXkV1lnX+3RChG4PBuOZSlbVH13gpOWvgeFmX40QrStWVzu8I
# F+qCZE3/I+PKhu60pCFkcOvV5aDaY7Mu6QXuqvYk9R28mxyyt1/f8O52fTGZZUdV
# nUokL6wrl76f5P17cz4y7lI0+9S769SgLDSb495uZBkHNwGRDxy1Uc2qTGaDiGhi
# u7xBG3gZbeTZD+BYQfvYsSzhUa+0rRUGFOpiCBPTaR58ZE2dD9/O0V6MqqtQFcmz
# yrzXxDtoRKOlO0L9c33u3Qr/eTQQfqZcClhMAD6FaXXHg2TWdc2PEnZWpST618Rr
# IbroHzSYLzrqawGw9/sqhux7UjipmAmhcbJsca8+uG+W1eEQE/5hRwqM/vC2x9XH
# 3mwk8L9CgsqgcT2ckpMEtGlwJw1Pt7U20clfCKRwo+wK8REuZODLIivK8SgTIUlR
# fgZm0zu++uuRONhRB8qUt+JQofM604qDy0B7AgMBAAGjggGLMIIBhzAOBgNVHQ8B
# Af8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZ
# bU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFKW27xPn783QZKHVVqllMaPe1eNJ
# MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAG
# CCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQw
# DQYJKoZIhvcNAQELBQADggIBAIEa1t6gqbWYF7xwjU+KPGic2CX/yyzkzepdIpLs
# jCICqbjPgKjZ5+PF7SaCinEvGN1Ott5s1+FgnCvt7T1IjrhrunxdvcJhN2hJd6Pr
# kKoS1yeF844ektrCQDifXcigLiV4JZ0qBXqEKZi2V3mP2yZWK7Dzp703DNiYdk9W
# uVLCtp04qYHnbUFcjGnRuSvExnvPnPp44pMadqJpddNQ5EQSviANnqlE0PjlSXcI
# WiHFtM+YlRpUurm8wWkZus8W8oM3NG6wQSbd3lqXTzON1I13fXVFoaVYJmoDRd7Z
# ULVQjK9WvUzF4UbFKNOt50MAcN7MmJ4ZiQPq1JE3701S88lgIcRWR+3aEUuMMsOI
# 5ljitts++V+wQtaP4xeR0arAVeOGv6wnLEHQmjNKqDbUuXKWfpd5OEhfysLcPTLf
# ddY2Z1qJ+Panx+VPNTwAvb6cKmx5AdzaROY63jg7B145WPR8czFVoIARyxQMfq68
# /qTreWWqaNYiyjvrmoI1VygWy2nyMpqy0tg6uLFGhmu6F/3Ed2wVbK6rr3M66ElG
# t9V/zLY4wNjsHPW2obhDLN9OTH0eaHDAdwrUAuBcYLso/zjlUlrWrBciI0707NMX
# +1Br/wd3H3GXREHJuEbTbDJ8WC9nR2XlG3O2mflrLAZG70Ee8PBf4NvZrZCARK+A
# EEGKMYIFGDCCBRQCAQEwQjAuMSwwKgYDVQQDDCNJbnR1bmUgUG93ZXJTaGVsbCBD
# b2RlIFNpZ25pbmcgQ2VydAIQZoU/OiTHx5lIkdHs+Ca1ijANBglghkgBZQMEAgEF
# AKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3
# DQEJBDEiBCBW1sqqy6x0V3hxcibRZ6lvUtN/ykhqY36OfXfAkAHMmjANBgkqhkiG
# 9w0BAQEFAASCAQAlwFX7H8Qjfk2xoVbOiYIxJHA7/8Uv9OLmSbv/KOGG8ACcNViE
# N7mcpHcuGK5zs+yuJG/iSyvuL4nIxNTDnlM1p7yfInOR5qmEuPbK2YaFsJoKuetc
# UAeFrPeDdLDcsatFyBNrW5D/ntMwetZGTlpZ/8G8mCMVtmv9rOU/nO7QjXp0oh6V
# jkOJmUskiUL9Fy738jlIhHXYwkk6f9L2zyDlhY1nDWyu+1UoJs0x227KKvMibi39
# KxVdhGNUsO9MRXPh6ejVu+5IP32rr99M6QfQjhC0Ldf83QrmfuEyveM32fOBIBoG
# tPhSgbqrTgkQK84gf/LLOwKy+SriQZar2FXzoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDYyODE2MDAyNVowLwYJKoZIhvcNAQkEMSIEILqDCQcUflV/yBCso3pHwu8SnUpH
# 7iB01H952WJWvBq1MA0GCSqGSIb3DQEBAQUABIICAGzT9aTow1unJg2obvLS2Zl7
# t91PNXgfEQZ/vttfW4UnxyU4t3PxXwpWbYU3MmGt8v7yf9UtlSYj/0kX72IxDPDi
# cdINb0mdHsuR8UHZPfVlhbDMHAWx1Z/6OFrq8kBf/o8lKfWFxHxgbwnP5pppXniD
# O2L7gTn/P7FeKOnNH//VBoaLqN/bv/nKnj4KGEFBi3zKkB0ovit1qJOmlOwAAS9T
# EFOlmExMiMXRrLZ41Hgu1UaJmAjn2uWpQqhknlaWfiAvWO38Aiqhe1QDDA0KTlj1
# a/TmDCTr6ZLN6jbAuh+9hYZ9fZtR/hgpVyt9zNc+OnF2oo2+5RFoYlaHPWHhWsu1
# r5WrkYxZ8snZKzm/Qw1SVA1CCsm0U/NqntRfMTCxh50a3IXPa2EH4PiVbqPXTKqE
# x0q7rvAI8e6pHKG5IHh4edDSOomS0ktrGVB5qDGxyX7qpemr4EM3QW4r7btxGxI2
# xIsVNkomP4hU2GR17ajxwc7DtDrMSDli0C2dQIwylv0KLTckSgS6hjI1vfX5vWHc
# HZf6uAnmEFywDWd4ME8d9cTu5Bd2jLYm15JD9HDdGVAqqhG/EvR5f1YgqBUsiA0f
# lPfJAUDbsqzLqhfW+A5oj/arnG+1Edo7KTdBesJfhG5Mkt1BqFtdcZhGVDhRtXpu
# 7LVo+8C/MdsR/4vFtJLw
# SIG # End signature block
