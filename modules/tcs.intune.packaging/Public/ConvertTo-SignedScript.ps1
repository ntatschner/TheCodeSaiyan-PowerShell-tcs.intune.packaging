function ConvertTo-SignedScript {
    <#
    .SYNOPSIS
        Signs PowerShell script files with a PFX certificate.

    .DESCRIPTION
        The ConvertTo-SignedScript function signs PowerShell script files (.ps1, .psm1, .psd1) using a specified PFX certificate file.
        This function validates that the input files are PowerShell scripts and that the certificate file is valid before signing.

    .PARAMETER Path
        The path to one or more PowerShell script files to sign. Accepts pipeline input.
        Validates that files exist, have valid extensions (.ps1, .psm1, .psd1), and contain content.

    .PARAMETER CertificateFile
        The path to the PFX certificate file used for signing.
        Must be a valid .pfx file that exists and contains data.

    .PARAMETER Password
        The password for the PFX certificate file as a SecureString.

    .EXAMPLE
        ConvertTo-SignedScript -Path "C:\Scripts\MyScript.ps1" -CertificateFile "C:\Certs\MyCert.pfx" -Password (ConvertTo-SecureString "MyPassword" -AsPlainText -Force)
        
        Signs the specified PowerShell script with the provided certificate.

    .EXAMPLE
        Get-ChildItem -Path "C:\Scripts\*.ps1" | ConvertTo-SignedScript -CertificateFile "C:\Certs\MyCert.pfx" -Password $securePass
        
        Signs all PowerShell scripts in the specified directory using pipeline input.

    .NOTES
        The certificate must be valid for code signing and trusted on the system where the scripts will run.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
                if (-not (Test-Path -Path $_)) {
                    throw "File not found: $_"
                }
                if ($_ -notmatch '.') {
                    throw "File must have an extension: $_"
                }
                $FileExtention = $_.Split('.')[-1]
                if ($FileExtention -notmatch "(ps1|psm1|psd1)$") {
                    throw "File must be a PowerShell script: $_"
                }
                if (-not (Get-Content -Path $_)) {
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
                foreach ($i in $_) {
                    if ((Split-Path -Path $_ -Leaf) -notmatch ".*\.pfx$") {
                        throw "File must be a PFX Certificate File: $_"
                    }
                    if (-not (Test-Path -Path $_)) {
                        throw "File not found: $_"
                    }
                    if (-not (Get-Content -Path $_)) {
                        throw "File is empty: $_"
                    }
                    $true
                }
            })]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateFile,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [securestring]
        $Password
    )
    begin {
        try {
            if (-not (Get-Module -Name Microsoft.PowerShell.Security -ListAvailable -ErrorAction SilentlyContinue)) {
                Install-Module -Name Microsoft.PowerShell.Security -Force -ErrorAction Stop
            }
            Import-Module Microsoft.PowerShell.Security -ErrorAction Stop
        }
        catch {
            Write-Error -Message "Failed to import Microsoft.PowerShell.Security: $_"
            break
        }
        try {
            $CertificateObject = Get-PfxCertificate -FilePath $CertificateFile -Password $Password
        }
        catch {
            Write-Error -Message "Failed to load certificate.`nError Message: $($_.Exception.Message)`nFull Error: $($_.ScriptStackTrace)`nError Type: $($_.FullyQualifiedErrorId)`n Certificate Path: $CertificateFile`n Password Type: $($Password.GetType())`n"
            break
        }
    } 
    process {
        foreach ($Script in $Path) {
            try {
                Set-AuthenticodeSignature -Certificate $CertificateObject -TimestampServer "http://timestamp.digicert.com" -FilePath $Path -ErrorAction Stop
            }
            catch {
                Write-Error -Message "Failed to sign script: $_`n Script: $Script`n"
                continue
            }
        }
    }
    end {

    }
}
# SIG # Begin signature block
# MIIb+wYJKoZIhvcNAQcCoIIb7DCCG+gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCUvDwwCHL/82cv
# Oob+pLhFkOMaWQmJOv6ic5uWi1fa3aCCFjkwggMsMIICFKADAgECAhBmhT86JMfH
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
# DQEJBDEiBCDan8otFbFdFNGlZWzGpx5lHBOtD0b/BEp6QwXXAdUuizANBgkqhkiG
# 9w0BAQEFAASCAQC+WZk6OO5Jcr8cmsxmha0i6GrgH6MZf/dDdmw9VFV/UjF0MJvA
# b/tV11QGJVg/rKLMsH+mK4UdNuZU3z+y2v7Ko92+yKJhXI4PQwD+NnLJ6aN9pIL/
# 7GBEWmU0Gd2fNzNKycuuZm2ZF2j995a+rzPRmD0OcN4vjD6NYt6QuVSkU+ci4m/g
# 3H4LQD7lB/pStufwgmAvH994BYYYrK5Pr85hzbAl4GcTmVuodnmBEtGMPscNCjY+
# kj7O/Fc6U+wn0f3gRlWA3miKmTos286+KclnrmajvQF7RJWKDxfm3cgMehoIJF7x
# SQ7s2Jysl96Kdr042K+j8GZXkTZ+Nb+tdbwyoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDYyODE2MDAyNVowLwYJKoZIhvcNAQkEMSIEIBF0SgwrMwpgaWGvUPwrB97ESUsA
# qCuMharm1KbK3GDEMA0GCSqGSIb3DQEBAQUABIICAGBu1hapjVSqTDjtnz/Hdpo8
# dIZqGjAJxrk2FloFF6ercrsMHB+KNjH7xKCztEEwv625gkLRjI6cOYRHKEHeWV2Y
# 9pk0wE4U/XWkM0bEUmCKAT+CH9YxCAY7YJFJdpltMkDef0njarPAU+odwuRv9y9w
# pziYJuZxBdpCL+VkNlET06j7uvgNMwoufkL3oj12p3aAf+RoiRJq/QL+knH7xgdi
# xJzxzJVyQ6qrVl9jVTRUT64VrcglxuIkoA2g5+XTx6t2B3DouOL1oCNCnE5EnHGV
# t1k+AjkDQdkkR2TQlcRHQMlgsF7ZbA6Bm1+6x6+6BC8kgDy4gMKHlrii04/iTy0g
# /90gBgoDDSmnXwuP5AhEvW6Euq0exmvcXDoqFJiSBUCSPLt+VurnLRynLgcQaZn7
# T5OXBSh25IIy8APgr5PRo0UMt3h8NUZ6Qrgg3E9ZGM4tdkEQDRD9DSqhR2MwPdQT
# HZ0gO/o4GKc0WcZIe6cLQmz2fsDNSmBam7fTKFJpul1/nguRZSzXRgyk+OMFxt0R
# FpHUzI3KNFOarWWxuBccGRjzx28CerC9b8iGta/i/vYl8kwucPbCwng1sDQFF7Sy
# iuiy6uKCPIy/sWgYMIoe1pddfDJjT9vAVJBK74EpZ9lfvOIs25EA1Xm6eiCckGBI
# BktCk8HRUeCoI1kLeebz
# SIG # End signature block
