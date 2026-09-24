# Test helper: builds a minimal .intunewin file (a zip with Detection.xml and encrypted content)
function New-TestIntuneWin {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [int]$ContentSize = 1024,

        [string]$SetupFile = 'setup.exe'
    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $root = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "intunewin-$([guid]::NewGuid().ToString('N'))"
    $package = Join-Path -Path $root -ChildPath 'IntuneWinPackage'
    $null = New-Item -Path (Join-Path -Path $package -ChildPath 'Metadata') -ItemType Directory -Force
    $null = New-Item -Path (Join-Path -Path $package -ChildPath 'Contents') -ItemType Directory -Force
    $bytes = New-Object -TypeName byte[] -ArgumentList $ContentSize
    (New-Object -TypeName System.Random -ArgumentList 42).NextBytes($bytes)
    [System.IO.File]::WriteAllBytes((Join-Path -Path $package -ChildPath 'Contents/IntunePackage.intunewin'), $bytes)
    $xml = @"
<ApplicationInfo xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ToolVersion="1.8.6">
  <Name>$SetupFile</Name>
  <UnencryptedContentSize>$($ContentSize - 48)</UnencryptedContentSize>
  <FileName>IntunePackage.intunewin</FileName>
  <SetupFile>$SetupFile</SetupFile>
  <EncryptionInfo>
    <EncryptionKey>ZW5jcnlwdGlvbktleQ==</EncryptionKey>
    <MacKey>bWFjS2V5</MacKey>
    <InitializationVector>aW5pdGlhbGl6YXRpb25WZWN0b3I=</InitializationVector>
    <Mac>bWFj</Mac>
    <ProfileIdentifier>ProfileVersion1</ProfileIdentifier>
    <FileDigest>ZmlsZURpZ2VzdA==</FileDigest>
    <FileDigestAlgorithm>SHA256</FileDigestAlgorithm>
  </EncryptionInfo>
</ApplicationInfo>
"@
    Set-Content -Path (Join-Path -Path $package -ChildPath 'Metadata/Detection.xml') -Value $xml -Encoding UTF8
    if (Test-Path -Path $Path) {
        Remove-Item -Path $Path -Force
    }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($root, $Path)
    Remove-Item -Path $root -Recurse -Force
    Get-Item -Path $Path
}

# Test helper: defines global stand-ins for Microsoft Graph commands that are not installed, so
# they can be mocked. Returns the names it defined.
function Add-GraphCommandStub {
    $defined = @()
    if (-not (Get-Command -Name Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
        function global:Invoke-MgGraphRequest {
            param($Method, $Uri, $Body, $ContentType, $OutputType)
        }
        $defined += 'Invoke-MgGraphRequest'
    }
    if (-not (Get-Command -Name Get-MgContext -ErrorAction SilentlyContinue)) {
        function global:Get-MgContext {
            param()
        }
        $defined += 'Get-MgContext'
    }
    $defined
}
