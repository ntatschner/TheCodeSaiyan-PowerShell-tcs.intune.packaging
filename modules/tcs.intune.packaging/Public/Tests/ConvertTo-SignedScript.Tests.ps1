BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}
Describe 'ConvertTo-SignedScript' {
    BeforeAll {
        # Set-AuthenticodeSignature only exists on Windows; give Pester something to mock elsewhere
        $script:DefinedStub = $false
        if (-not (Get-Command -Name Set-AuthenticodeSignature -ErrorAction SilentlyContinue)) {
            function global:Set-AuthenticodeSignature {
                param($Certificate, $TimestampServer, $FilePath)
            }
            $script:DefinedStub = $true
        }

        # Self-signed code signing certificate exported to a PFX file
        $rsa = [System.Security.Cryptography.RSA]::Create(2048)
        $request = New-Object -TypeName System.Security.Cryptography.X509Certificates.CertificateRequest -ArgumentList 'CN=tcs test signing', $rsa, ([System.Security.Cryptography.HashAlgorithmName]::SHA256), ([System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $certificate = $request.CreateSelfSigned([DateTimeOffset]::Now.AddDays(-1), [DateTimeOffset]::Now.AddDays(1))
        # A throw-away password for a throw-away test certificate
        function ConvertTo-TestSecureString([string]$Text) {
            $secure = New-Object -TypeName System.Security.SecureString
            foreach ($character in $Text.ToCharArray()) {
                $secure.AppendChar($character)
            }
            $secure
        }
        $script:Password = ConvertTo-TestSecureString 'pfx-test-password'
        $script:PfxPath = Join-Path -Path $TestDrive -ChildPath 'signing.pfx'
        [System.IO.File]::WriteAllBytes($script:PfxPath, $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, 'pfx-test-password'))

        $script:Scripts = foreach ($name in 'one.ps1', 'two.psm1') {
            $path = Join-Path -Path $TestDrive -ChildPath $name
            Set-Content -Path $path -Value 'Write-Output 1'
            $path
        }
    }

    AfterAll {
        if ($script:DefinedStub) {
            Remove-Item -Path Function:\Set-AuthenticodeSignature -ErrorAction SilentlyContinue
        }
    }

    It 'Signs each file exactly once' {
        Mock -ModuleName tcs.intune.packaging Set-AuthenticodeSignature { }
        ConvertTo-SignedScript -Path $script:Scripts -CertificateFile $script:PfxPath -Password $script:Password
        Should -Invoke -ModuleName tcs.intune.packaging Set-AuthenticodeSignature -Times 2 -Exactly
        foreach ($path in $script:Scripts) {
            Should -Invoke -ModuleName tcs.intune.packaging Set-AuthenticodeSignature -Times 1 -Exactly -ParameterFilter { $FilePath -eq $path }
        }
    }

    It 'Loads the certificate with its private key' {
        Mock -ModuleName tcs.intune.packaging Set-AuthenticodeSignature { }
        ConvertTo-SignedScript -Path $script:Scripts[0] -CertificateFile $script:PfxPath -Password $script:Password
        Should -Invoke -ModuleName tcs.intune.packaging Set-AuthenticodeSignature -Times 1 -Exactly -ParameterFilter { $Certificate.HasPrivateKey -and $Certificate.Subject -eq 'CN=tcs test signing' }
    }

    It 'Throws for a wrong certificate password' {
        $wrong = ConvertTo-TestSecureString 'wrong'
        { ConvertTo-SignedScript -Path $script:Scripts[0] -CertificateFile $script:PfxPath -Password $wrong } | Should -Throw '*Failed to load certificate*'
    }

    It 'Rejects files that are not PowerShell scripts' {
        $text = Join-Path -Path $TestDrive -ChildPath 'notes.txt'
        Set-Content -Path $text -Value 'x'
        { ConvertTo-SignedScript -Path $text -CertificateFile $script:PfxPath -Password $script:Password } | Should -Throw '*PowerShell script*'
    }

    It 'Signs nothing with -WhatIf' {
        Mock -ModuleName tcs.intune.packaging Set-AuthenticodeSignature { }
        ConvertTo-SignedScript -Path $script:Scripts -CertificateFile $script:PfxPath -Password $script:Password -WhatIf
        Should -Invoke -ModuleName tcs.intune.packaging Set-AuthenticodeSignature -Times 0 -Exactly
    }
}
