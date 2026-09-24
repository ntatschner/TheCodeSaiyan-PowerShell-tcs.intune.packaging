function Test-IntuneLogoImage {
    <#
    .SYNOPSIS
        Tests that an image can be used as an Intune application logo.

    .DESCRIPTION
        Returns $true when the file exists, is a PNG or JPG (.png, .jpg or .jpeg) and is at most
        256x256 pixels. Otherwise writes an error and returns $false.
        Reading the image size uses System.Drawing, which needs Windows.

    .PARAMETER Path
        The path of the image file to validate.

    .EXAMPLE
        Test-IntuneLogoImage -Path "C:\path\to\image.png"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    process {
        $FileName = Split-Path -Path $Path -Leaf
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "The image '$FileName' does not exist."
            return $false
        }
        $extension = [System.IO.Path]::GetExtension($Path)
        if ($extension -notin @('.png', '.jpg', '.jpeg')) {
            Write-Error "The image '$FileName' is not a PNG or JPG."
            return $false
        }
        # System.Drawing is not loaded by default in Windows PowerShell 5.1
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $image = [System.Drawing.Image]::FromFile((Resolve-Path -Path $Path).ProviderPath)
        try {
            if ($image.Width -gt 256 -or $image.Height -gt 256) {
                Write-Error "The image '$FileName' is larger than 256x256 pixels."
                return $false
            }
        }
        finally {
            $image.Dispose()
        }
        return $true
    }
}
