function Assert-SafePathSegment {
    <#
    .SYNOPSIS
        Throws when a name cannot safely be used as a single file or folder name.

    .DESCRIPTION
        Package and file names built from user input (application names, versions) are joined to an
        output folder. This rejects names that are empty, '.' or '..', contain a path separator or a
        character that Windows does not allow in file names (< > : " | ? * and control characters),
        or end with a space or a dot. Unless AllowWildcard is used, the wildcard characters [ and ]
        are rejected too, because APF detection and installer scripts pass the name to -Path
        parameters that expand wildcards.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Name,

        [string]$ParameterName = 'Name',

        [switch]$AllowWildcard
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "$ParameterName must not be empty."
    }
    if ($Name -eq '.' -or $Name -eq '..') {
        throw "$ParameterName '$Name' is not a valid name."
    }
    $Invalid = @('\', '/', '<', '>', ':', '"', '|', '?', '*')
    if (-not $AllowWildcard) {
        $Invalid += @('[', ']')
    }
    foreach ($Character in $Name.ToCharArray()) {
        if ([char]::IsControl($Character) -or $Invalid -contains [string]$Character) {
            throw "$ParameterName '$Name' contains the character '$Character', which cannot be used in a file or folder name. Do not use path separators, control characters or any of $($Invalid -join ' ')."
        }
    }
    if ($Name.EndsWith(' ') -or $Name.EndsWith('.')) {
        throw "$ParameterName '$Name' must not end with a space or a dot."
    }
}
