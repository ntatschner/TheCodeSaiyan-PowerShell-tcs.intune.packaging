function Get-PackageFolderPath {
    <#
    .SYNOPSIS
        Returns the full path of the package folder <DestinationFolder>/<Name>.

    .DESCRIPTION
        Validates Name with Assert-SafePathSegment and checks that the resulting folder is a direct
        child of DestinationFolder, so a package folder can never be the destination folder itself
        or a folder outside it. Callers delete this folder when it is overwritten.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]$DestinationFolder,

        [AllowEmptyString()]
        [AllowNull()]
        [string]$Name
    )

    Assert-SafePathSegment -Name $Name -ParameterName 'Name'
    $Destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationFolder)
    $Destination = [System.IO.Path]::GetFullPath($Destination).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $PackageFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Destination, $Name))
    $Parent = [System.IO.Path]::GetDirectoryName($PackageFolder)
    if ([string]::IsNullOrEmpty($Parent) -or $Parent.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) -ne $Destination) {
        throw "The package folder '$PackageFolder' is not a subfolder of the destination folder '$Destination'."
    }
    $PackageFolder
}
