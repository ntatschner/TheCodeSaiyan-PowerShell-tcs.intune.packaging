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
Describe 'Intune content upload helpers' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath '../../../../tests/TestHelpers/New-TestIntuneWin.ps1')
        $script:Stubs = Add-GraphCommandStub
    }

    AfterAll {
        foreach ($name in $script:Stubs) {
            Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
        }
    }

    Context 'Read-IntuneWinPackage' {
        It 'Reads Detection.xml and extracts the encrypted content' {
            $package = New-TestIntuneWin -Path (Join-Path -Path $TestDrive -ChildPath 'app.intunewin') -ContentSize 5000 -SetupFile 'install.cmd'
            $target = Join-Path -Path $TestDrive -ChildPath 'content.bin'
            $info = InModuleScope tcs.intune.packaging -Parameters @{ Path = $package.FullName; Target = $target } {
                Read-IntuneWinPackage -Path $Path -ExtractTo $Target
            }
            $info.FileName | Should -Be 'IntunePackage.intunewin'
            $info.SetupFile | Should -Be 'install.cmd'
            $info.UnencryptedContentSize | Should -Be 4952
            $info.EncryptedContentSize | Should -Be 5000
            (Get-Item -Path $target).Length | Should -Be 5000
            $info.EncryptionInfo.encryptionKey | Should -Be 'ZW5jcnlwdGlvbktleQ=='
            $info.EncryptionInfo.profileIdentifier | Should -Be 'ProfileVersion1'
            $info.EncryptionInfo.fileDigestAlgorithm | Should -Be 'SHA256'
            @($info.EncryptionInfo.Keys) | Should -Be @('encryptionKey', 'macKey', 'initializationVector', 'mac', 'profileIdentifier', 'fileDigest', 'fileDigestAlgorithm')
        }

        It 'Rejects a zip that is not a .intunewin package' {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $folder = Join-Path -Path $TestDrive -ChildPath 'notpkg'
            $null = New-Item -Path $folder -ItemType Directory -Force
            Set-Content -Path (Join-Path -Path $folder -ChildPath 'a.txt') -Value 'x'
            $zip = Join-Path -Path $TestDrive -ChildPath 'bad.intunewin'
            [System.IO.Compression.ZipFile]::CreateFromDirectory($folder, $zip)
            { InModuleScope tcs.intune.packaging -Parameters @{ Path = $zip } { Read-IntuneWinPackage -Path $Path } } | Should -Throw '*not a .intunewin package*'
        }
    }

    Context 'Send-IntuneContentFile' {
        BeforeEach {
            $script:Puts = [System.Collections.Generic.List[object]]::new()
            Mock -ModuleName tcs.intune.packaging Invoke-WebRequest {
                $length = $(if ($Body -is [byte[]]) { $Body.Length } else { $null })
                $script:Puts.Add([PSCustomObject]@{ Uri = $Uri; Method = $Method; Length = $length; Body = $(if ($Body -is [string]) { $Body } else { $null }); ContentType = $ContentType })
            }
        }

        It 'Uploads the file in blocks of equal-length IDs and commits the block list' {
            $file = Join-Path -Path $TestDrive -ChildPath 'upload.bin'
            [System.IO.File]::WriteAllBytes($file, (New-Object -TypeName byte[] -ArgumentList (2 * 1024 * 1024 + 100)))
            InModuleScope tcs.intune.packaging -Parameters @{ Path = $file } {
                Send-IntuneContentFile -Path $Path -SasUri 'https://blob.example/c/f?sv=1&sig=abc' -FileUri 'v1.0/files/1' -ChunkSizeMB 1
            }
            $script:Puts.Count | Should -Be 4
            $blocks = $script:Puts[0..2]
            @($blocks | ForEach-Object { $_.Length }) | Should -Be @(1048576, 1048576, 100)
            foreach ($i in 0..2) {
                $id = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($i.ToString('000000')))
                $blocks[$i].Uri | Should -Be "https://blob.example/c/f?sv=1&sig=abc&comp=block&blockid=$([System.Uri]::EscapeDataString($id))"
                $blocks[$i].Method | Should -Be 'Put'
            }
            $script:Puts[3].Uri | Should -Be 'https://blob.example/c/f?sv=1&sig=abc&comp=blocklist'
            $script:Puts[3].ContentType | Should -Be 'application/xml'
            ([xml]$script:Puts[3].Body).BlockList.Latest.Count | Should -Be 3
        }

        It 'Renews the SAS URI when the renewal interval has passed' {
            Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { } -ParameterFilter { $Method -eq 'POST' -and $Uri -eq 'v1.0/files/1/renewUpload' }
            Mock -ModuleName tcs.intune.packaging Wait-IntuneContentFileState { [PSCustomObject]@{ azureStorageUri = 'https://blob.example/c/f?sv=2&sig=new'; uploadState = $State } }
            $file = Join-Path -Path $TestDrive -ChildPath 'small.bin'
            [System.IO.File]::WriteAllBytes($file, (New-Object -TypeName byte[] -ArgumentList 10))
            InModuleScope tcs.intune.packaging -Parameters @{ Path = $file } {
                Send-IntuneContentFile -Path $Path -SasUri 'https://blob.example/c/f?sv=1&sig=old' -FileUri 'v1.0/files/1' -RenewAfterSeconds 0
            }
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter { $Uri -eq 'v1.0/files/1/renewUpload' }
            Should -Invoke -ModuleName tcs.intune.packaging Wait-IntuneContentFileState -Times 1 -Exactly -ParameterFilter { $State -eq 'azureStorageUriRenewalSuccess' }
            $script:Puts[0].Uri | Should -BeLike 'https://blob.example/c/f?sv=2&sig=new&comp=block*'
        }
    }

    Context 'Send-IntuneContentFile retries' {
        BeforeAll {
            if (-not ('IntunePackagingTests.FakeWebResponse' -as [type])) {
                # Stands in for System.Net.HttpWebResponse, which cannot be constructed
                Add-Type -IgnoreWarnings -TypeDefinition @'
namespace IntunePackagingTests
{
    public class FakeWebResponse : System.Net.WebResponse
    {
        private readonly System.Net.WebHeaderCollection headers = new System.Net.WebHeaderCollection();

        public FakeWebResponse(int statusCode)
        {
            StatusCode = (System.Net.HttpStatusCode)statusCode;
        }

        public System.Net.HttpStatusCode StatusCode { get; private set; }
        public string StatusDescription { get { return "Error"; } }
        public override System.Net.WebHeaderCollection Headers { get { return headers; } }
        public override System.IO.Stream GetResponseStream() { return new System.IO.MemoryStream(); }
    }
}
'@
            }

            # The shape of a failed Azure Storage request: a WebException with the HTTP response,
            # or without a response for a timeout
            function New-StorageException {
                param([int]$StatusCode, [string]$RetryAfter)
                if (-not $StatusCode) {
                    return (New-Object System.Net.WebException -ArgumentList 'The operation has timed out.', $null, ([System.Net.WebExceptionStatus]::Timeout), $null)
                }
                $response = New-Object IntunePackagingTests.FakeWebResponse -ArgumentList $StatusCode
                if ($RetryAfter) {
                    $response.Headers.Add('Retry-After', $RetryAfter)
                }
                New-Object System.Net.WebException -ArgumentList "The remote server returned an error: ($StatusCode).", $null, ([System.Net.WebExceptionStatus]::ProtocolError), $response
            }

            $script:UploadFile = Join-Path -Path $TestDrive -ChildPath 'retry.bin'
            $bytes = New-Object -TypeName byte[] -ArgumentList 1000
            for ($i = 0; $i -lt $bytes.Length; $i++) {
                $bytes[$i] = [byte]($i % 251)
            }
            [System.IO.File]::WriteAllBytes($script:UploadFile, $bytes)
            $script:SasUri = 'https://blob.example/c/f?sv=1&sig=abc'
        }

        BeforeEach {
            # Invoke-WithRetry runs in tcs.core, so its Start-Sleep is mocked there: no real waits
            Mock -ModuleName tcs.core Start-Sleep { }
            $script:Puts = [System.Collections.Generic.List[object]]::new()
            # Status codes (or 'timeout') to fail the next requests with, in order
            $script:Failures = [System.Collections.Generic.Queue[object]]::new()
            $script:FailComp = 'block'
            Mock -ModuleName tcs.intune.packaging Invoke-WebRequest {
                $script:Puts.Add([PSCustomObject]@{
                        Uri  = $Uri
                        Body = $(if ($Body -is [byte[]]) { [System.Convert]::ToBase64String($Body) } else { $Body })
                    })
                if ($Uri -like "*&comp=$($script:FailComp)*" -and $script:Failures.Count -gt 0) {
                    $failure = $script:Failures.Dequeue()
                    if ($failure -eq 'timeout') {
                        throw (New-StorageException)
                    }
                    if ($failure -is [hashtable]) {
                        throw (New-StorageException @failure)
                    }
                    throw (New-StorageException -StatusCode $failure)
                }
            }
        }

        It 'Sends the same block again after HTTP 503 and then succeeds' {
            $script:Failures.Enqueue(503)
            InModuleScope tcs.intune.packaging -Parameters @{ Path = $script:UploadFile; SasUri = $script:SasUri } {
                Send-IntuneContentFile -Path $Path -SasUri $SasUri -FileUri 'v1.0/files/1'
            }
            $blocks = @($script:Puts | Where-Object { $_.Uri -like '*&comp=block&*' })
            $blocks.Count | Should -Be 2
            $blocks[1].Uri | Should -Be $blocks[0].Uri
            $blocks[1].Body | Should -Be $blocks[0].Body
            $blocks[1].Body | Should -Be ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($script:UploadFile)))
            @($script:Puts | Where-Object { $_.Uri -like '*&comp=blocklist' }).Count | Should -Be 1
            Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 2000 }
        }

        It 'Retries the block list after HTTP 500' {
            $script:FailComp = 'blocklist'
            $script:Failures.Enqueue(500)
            InModuleScope tcs.intune.packaging -Parameters @{ Path = $script:UploadFile; SasUri = $script:SasUri } {
                Send-IntuneContentFile -Path $Path -SasUri $SasUri -FileUri 'v1.0/files/1'
            }
            @($script:Puts | Where-Object { $_.Uri -like '*&comp=blocklist' }).Count | Should -Be 2
        }

        It 'Retries a request that failed without an HTTP response' {
            $script:Failures.Enqueue('timeout')
            InModuleScope tcs.intune.packaging -Parameters @{ Path = $script:UploadFile; SasUri = $script:SasUri } {
                Send-IntuneContentFile -Path $Path -SasUri $SasUri -FileUri 'v1.0/files/1'
            }
            @($script:Puts | Where-Object { $_.Uri -like '*&comp=block&*' }).Count | Should -Be 2
        }

        It 'Waits for the Retry-After of HTTP 429 when it is longer than the backoff' {
            $script:Failures.Enqueue(@{ StatusCode = 429; RetryAfter = '7' })
            InModuleScope tcs.intune.packaging -Parameters @{ Path = $script:UploadFile; SasUri = $script:SasUri } {
                Send-IntuneContentFile -Path $Path -SasUri $SasUri -FileUri 'v1.0/files/1'
            }
            Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 7000 }
        }

        It 'Does not retry HTTP 400' {
            $script:Failures.Enqueue(400)
            {
                InModuleScope tcs.intune.packaging -Parameters @{ Path = $script:UploadFile; SasUri = $script:SasUri } {
                    Send-IntuneContentFile -Path $Path -SasUri $SasUri -FileUri 'v1.0/files/1'
                }
            } | Should -Throw '*(400)*'
            $script:Puts.Count | Should -Be 1
            Should -Invoke -ModuleName tcs.core Start-Sleep -Times 0 -Exactly
        }

        It 'Gives up after 3 attempts and throws the last error' {
            1..3 | ForEach-Object { $script:Failures.Enqueue(503) }
            {
                InModuleScope tcs.intune.packaging -Parameters @{ Path = $script:UploadFile; SasUri = $script:SasUri } {
                    Send-IntuneContentFile -Path $Path -SasUri $SasUri -FileUri 'v1.0/files/1'
                }
            } | Should -Throw '*(503)*'
            $script:Puts.Count | Should -Be 3
            @($script:Puts | Where-Object { $_.Uri -like '*&comp=blocklist' }).Count | Should -Be 0
            Should -Invoke -ModuleName tcs.core Start-Sleep -Times 2 -Exactly
            Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 2000 }
            Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 4000 }
        }
    }

    Context 'Wait-IntuneContentFileState' {
        BeforeEach {
            Mock -ModuleName tcs.intune.packaging Start-Sleep { }
        }

        It 'Polls until the state is reached' {
            $script:States = [System.Collections.Generic.Queue[string]]::new([string[]]@('azureStorageUriRequestPending', 'azureStorageUriRequestSuccess'))
            Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ uploadState = $script:States.Dequeue(); azureStorageUri = 'https://blob.example/x?sig=1' } }
            $file = InModuleScope tcs.intune.packaging { Wait-IntuneContentFileState -FileUri 'v1.0/files/1' -State azureStorageUriRequestSuccess -PollIntervalSeconds 0 }
            $file.azureStorageUri | Should -Be 'https://blob.example/x?sig=1'
            Should -Invoke -ModuleName tcs.intune.packaging Invoke-MgGraphRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Uri -eq 'v1.0/files/1' }
        }

        It 'Throws on a failed state' {
            Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ uploadState = 'commitFileFailed' } }
            { InModuleScope tcs.intune.packaging { Wait-IntuneContentFileState -FileUri 'v1.0/files/1' -State commitFileSuccess -PollIntervalSeconds 0 } } | Should -Throw '*commitFileFailed*'
        }

        It 'Throws after the timeout' {
            Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest { [PSCustomObject]@{ uploadState = 'commitFilePending' } }
            { InModuleScope tcs.intune.packaging { Wait-IntuneContentFileState -FileUri 'v1.0/files/1' -State commitFileSuccess -PollIntervalSeconds 0 -TimeoutSeconds 0 } } | Should -Throw '*Timed out*'
        }
    }

    Context 'Publish-IntuneWin32AppContent' {
        It 'Runs the documented Graph sequence and commits the encryption info from Detection.xml' {
            $package = New-TestIntuneWin -Path (Join-Path -Path $TestDrive -ChildPath 'flow.intunewin') -ContentSize 3000
            $script:Requests = [System.Collections.Generic.List[object]]::new()
            $script:FileStates = [System.Collections.Generic.Queue[string]]::new([string[]]@('azureStorageUriRequestPending', 'azureStorageUriRequestSuccess', 'commitFileSuccess'))
            Mock -ModuleName tcs.intune.packaging Start-Sleep { }
            Mock -ModuleName tcs.intune.packaging Invoke-WebRequest { $script:Requests.Add("BLOB $Method $Uri") }
            Mock -ModuleName tcs.intune.packaging Invoke-MgGraphRequest {
                $script:Requests.Add([PSCustomObject]@{ Method = $Method; Uri = $Uri; Body = $Body })
                switch -Wildcard ("$Method $Uri") {
                    'POST */contentVersions' { return [PSCustomObject]@{ id = '7' } }
                    'POST */files' { return [PSCustomObject]@{ id = 'file-1'; uploadState = 'azureStorageUriRequestPending' } }
                    'GET */files/file-1' { return [PSCustomObject]@{ id = 'file-1'; uploadState = $script:FileStates.Dequeue(); azureStorageUri = 'https://blob.example/c/f?sig=1' } }
                    default { return $null }
                }
            }

            $version = InModuleScope tcs.intune.packaging -Parameters @{ Path = $package.FullName } {
                Publish-IntuneWin32AppContent -AppId 'app-1' -IntuneWinPath $Path -PollIntervalSeconds 0
            }
            $version | Should -Be '7'

            $graph = @($script:Requests | Where-Object { $_ -isnot [string] })
            $sequence = $graph | ForEach-Object { "$($_.Method) $($_.Uri)" }
            $base = 'v1.0/deviceAppManagement/mobileApps/app-1'
            $sequence | Should -Be @(
                "POST $base/microsoft.graph.win32LobApp/contentVersions"
                "POST $base/microsoft.graph.win32LobApp/contentVersions/7/files"
                "GET $base/microsoft.graph.win32LobApp/contentVersions/7/files/file-1"
                "GET $base/microsoft.graph.win32LobApp/contentVersions/7/files/file-1"
                "POST $base/microsoft.graph.win32LobApp/contentVersions/7/files/file-1/commit"
                "GET $base/microsoft.graph.win32LobApp/contentVersions/7/files/file-1"
                "PATCH $base"
            )
            $fileBody = $graph[1].Body | ConvertFrom-Json
            $fileBody.name | Should -Be 'IntunePackage.intunewin'
            $fileBody.size | Should -Be 2952
            $fileBody.sizeEncrypted | Should -Be 3000
            $fileBody.isDependency | Should -BeFalse
            $commit = ($graph[4].Body | ConvertFrom-Json).fileEncryptionInfo
            $commit.encryptionKey | Should -Be 'ZW5jcnlwdGlvbktleQ=='
            $commit.macKey | Should -Be 'bWFjS2V5'
            $commit.initializationVector | Should -Be 'aW5pdGlhbGl6YXRpb25WZWN0b3I='
            $commit.mac | Should -Be 'bWFj'
            $commit.fileDigest | Should -Be 'ZmlsZURpZ2VzdA=='
            $patch = $graph[6].Body | ConvertFrom-Json
            $patch.'@odata.type' | Should -Be '#microsoft.graph.win32LobApp'
            $patch.committedContentVersion | Should -Be '7'
            # Blob upload happens between the storage URI and the commit
            $blobIndex = $script:Requests.IndexOf(($script:Requests | Where-Object { $_ -is [string] } | Select-Object -Last 1))
            $commitIndex = $script:Requests.IndexOf($graph[4])
            $blobIndex | Should -BeLessThan $commitIndex
            @($script:Requests | Where-Object { $_ -is [string] }) | Should -Be @(
                'BLOB Put https://blob.example/c/f?sig=1&comp=block&blockid=MDAwMDAw'
                'BLOB Put https://blob.example/c/f?sig=1&comp=blocklist'
            )
        }
    }
}
