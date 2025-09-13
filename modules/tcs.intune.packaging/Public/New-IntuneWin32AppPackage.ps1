function New-IntuneWin32AppPackage {    
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the source folder where the setup file and all of it's potential dependency files reside.")]
        [ValidateNotNullOrEmpty()]
        [string]$SourceFolder,

        [parameter(Mandatory = $true, HelpMessage = "Specify the complete setup file name including it's file extension, e.g. Setup.exe or Installer.msi.")]
        [ValidateNotNullOrEmpty()]
        [string]$SetupFile,

        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the output folder where the packaged .intunewin file will be exported to.")]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFolder,

        [parameter(Mandatory = $false, HelpMessage = "Specify to overwrite existing packaged .intunewin file if already present in output folder.")]
        [ValidateNotNullOrEmpty()]
        [switch]$Force,

        [parameter(Mandatory = $false, HelpMessage = "Specify the full path to the IntuneWinAppUtil.exe file.")]
        [ValidateNotNullOrEmpty()]
        [string]$IntuneWinAppUtilPath = (Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil.exe")
    )
    Process {
        # Trim trailing backslashes from input paths
        $SourceFolder = $SourceFolder.TrimEnd("\")
        $OutputFolder = $OutputFolder.TrimEnd("\")

        if ((Test-Path -Path $SourceFolder) -or (Test-Path -LiteralPath $SourceFolder)) {
            Write-Verbose -Message "Successfully detected specified source folder: $($SourceFolder)"

            $SetupFilePath = (Join-Path -Path $SourceFolder -ChildPath $SetupFile)
            if ((Test-Path -Path $SetupFilePath) -or (Test-Path -LiteralPath $SetupFilePath)) {
                Write-Verbose -Message "Successfully detected specified setup file '$($SetupFile)' in source folder"

                if ((Test-Path -Path $OutputFolder) -or (Test-Path -LiteralPath $OutputFolder)) {
                    Write-Verbose -Message "Successfully detected specified output folder: $($OutputFolder)"

                    if ((-not(Test-Path -Path $IntuneWinAppUtilPath)) -or (-not(Test-Path -LiteralPath $IntuneWinAppUtilPath))) {
                        if (-not($PSBoundParameters["IntuneWinAppUtilPath"])) {
                            # Download IntuneWinAppUtil.exe if not present in context temporary folder
                            Write-Verbose -Message "Unable to detect IntuneWinAppUtil.exe in specified location, attempting to download to: $($env:TEMP)"
                            Get-IntunePackagingTool -Path $env:TEMP

                            # Override path for IntuneWinApputil.exe if custom path was passed as a parameter, but was not found and downloaded to temporary location
                            $IntuneWinAppUtilPath = Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil.exe"
                        }
                    }

                    if ((Test-Path -Path $IntuneWinAppUtilPath) -or (Test-Path -LiteralPath $IntuneWinAppUtilPath)) {
                        Write-Verbose -Message "Successfully detected IntuneWinAppUtil.exe in: $($IntuneWinAppUtilPath)"

                        # If .intunewin already exists, only continue if Force parameter is passed on command line
                        $ProcessPackage = $true
                        $IntuneWinAppPackage = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFile)).intunewin"
                        if ((Test-Path -Path $IntuneWinAppPackage) -or (Test-Path -LiteralPath $IntuneWinAppPackage)) {
                            if ($Force) {
                                Write-Verbose -Message "Package file already exist, but Force parameter was specified to overwrite existing file"
                            }
                            else {
                                Write-Warning -Message "Package file already exist, specify the Force parameter to overwrite existing file"
                                $ProcessPackage = $false
                            }
                        }

                        # Continue processing if allowed
                        if ($ProcessPackage -eq $true) {
                            # Invoke IntuneWinAppUtil.exe with parameter inputs
                            Write-Verbose -Message "Invoking IntuneWinAppUtil.exe to initialize packaging process"
                            $PackageInvocation = Invoke-Executable -FilePath $IntuneWinAppUtilPath -Arguments "-c ""$($SourceFolder)"" -s ""$($SetupFile)"" -o ""$($OutPutFolder)"" -q" -RedirectStandardOutput $false -RedirectStandardError $false -CreateNoWindow $false -UseShellExecute $true
                            if ($PackageInvocation.ExitCode -eq 0) {
                                Write-Verbose -Message "IntuneWinAppUtil.exe packaging process completed with exit code $($PackageInvocation.ExitCode)"

                                # Test if .intunewin file exists after packaging process completed
                                if ((Test-Path -Path $IntuneWinAppPackage) -or (Test-Path -LiteralPath $IntuneWinAppPackage)) {
                                    Write-Verbose -Message "Successfully created Win32 app package object"

                                    # Retrieve Win32 app package meta data
                                    $IntuneWinAppMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinAppPackage

                                    # Construct output object with package details
                                    $PSObject = [PSCustomObject]@{
                                        "Name"                   = $IntuneWinAppMetaData.ApplicationInfo.Name
                                        "FileName"               = $IntuneWinAppMetaData.ApplicationInfo.FileName
                                        "SetupFile"              = $IntuneWinAppMetaData.ApplicationInfo.SetupFile
                                        "UnencryptedContentSize" = $IntuneWinAppMetaData.ApplicationInfo.UnencryptedContentSize
                                        "Path"                   = $IntuneWinAppPackage
                                    }
                                    Write-Output -InputObject $PSObject
                                }
                                else {
                                    Write-Warning -Message "Unable to detect expected '$($SetupFile).intunewin' file after IntuneWinAppUtil.exe invocation"
                                }
                            }
                            else {
                                Write-Warning -Message "Unexpected error occurred while packaging Win32 app. Return code from invocation: $($PackageInvocation.ExitCode)"
                            }
                        }
                    }
                    else {
                        Write-Warning -Message "Unable to detect IntuneWinAppUtil.exe in: $($IntuneWinAppUtilPath)"
                    }
                }
                else {
                    Write-Warning -Message "Unable to detect specified output folder: $($OutputFolder)"
                }
            }
            else {
                Write-Warning -Message "Unable to detect specified setup file '$($SetupFile)' in source folder: $($SourceFolder)"
            }
        }
        else {
            Write-Warning -Message "Unable to detect specified source folder: $($SourceFolder)"
        }
    }
}
# SIG # Begin signature block
# MIIb+wYJKoZIhvcNAQcCoIIb7DCCG+gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAs48thb4D2fmUW
# IZShWdyAkM51X+mJzwbhTFL/2MWL3KCCFjkwggMsMIICFKADAgECAhBmhT86JMfH
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
# DQEJBDEiBCDHrFp1zdBUc7WerArnISE4j3flrCrB1jqHcRLFLzHg7jANBgkqhkiG
# 9w0BAQEFAASCAQA0+ah1bC7aKqpmKkXRF+SUc02aB0zrqQaVc8P8clykVxCu71QF
# M4KpnpyXIQXG8oV6eUoaXvwfgpnVVnfLyg7RKe7TqnMwIvzg3rdc24tD7eMo2n2/
# AkmqkB615gFH4G83eY1ZmaO0vaDG31m6+d4jF/ArQNw6Ww/A7j92H80FvOmh6Sb8
# xq4cYmWWgz05Y2Htp8nvY+kQj0TQspS+Nq6R5TnWgrZnSyIwtAvtFJnoSmjuEKrS
# UxxLFANss61HAQcDXlEgTZPG8d8+GZ9RL1ZCE5RFC/yJ28MlJx67Vky070t5x0+E
# wjzFuiNC5juq7KtFOODaYG98deIlY/m9QEPvoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDYyODE2MDAyNlowLwYJKoZIhvcNAQkEMSIEIAlN+YtSszo14g6vvmcxescgFSwv
# hCLqYvh4F8HVkLEUMA0GCSqGSIb3DQEBAQUABIICAIo+P/zQdurWvXz4bc2sIFAj
# etPZmohFRYOgVXMI2R9gBhLPYzKs9SnE1XOnkdZ1H/J1gwxjB/TV0NzQAbtWYMVM
# bzQam4kHecVArodcj9zN2inlj8hkTCQPdlxJOVnwWn4cl3kU07dpwm/7LvZzs7gv
# 7QuWj+h4qoj0iz5z6Sbdaz9APhl8Ha1q4swj81A2dgTokkhmXQsZVY9bRrGT4Wd1
# BNC1caI/1WETfCqTfIHmU34xF5eRzj4AYePbYa8vDj5a/OB/qipu2Wsq3DauK+2k
# KDV1Wa5aKbNZUfCzm6D6D5Gw/wELgiRkp1VUMlS6xE+mqvMqy+WodaJFZEmQWcNW
# pHUk/7G6RdSFqGsqpuIM6ad0qZIGIbC3wkTUkiElH7vas6Ac3hPx98sQl71dIsY4
# 1IP3a9LtZKjH7jgI/kNsemeAvVNMvqVcNlIPUSXVl7P7QzmxbuA6Q1+bh2moqvX1
# RrzhwqIN4tNKAaanw9vgNPsVLts4Z2XRAIVjwBKvFQqsWZY66aGjye6QFGo2Hani
# IbMgIcKKDeuCzWPe2sDL1u2y+AMV307WZL9tNPS7DyfYhhCgMSIDCo7qaZtFB2di
# wgiZvFnSz3jBAccy8hmSljGa3OjowShZmlT8vAE7uuW1+/p+qkSWLZEl26/2a/iW
# LfU5V6i2bQ9DBkXenBfi
# SIG # End signature block
