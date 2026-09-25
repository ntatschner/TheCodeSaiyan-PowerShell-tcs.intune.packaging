function Set-TemplateToken {
    <#
    .SYNOPSIS
        Replaces ##<TOKEN>_TEMPLATE placeholders in an APF installer script.

    .DESCRIPTION
        Every placeholder in the template scripts sits inside a single-quoted PowerShell string
        (for example $AppName = '##NAME_TEMPLATE'), so each value is inserted with single quotes
        doubled. A value can therefore never end the string and run as code. The script is parsed
        after the replacement and an error is thrown when it no longer parses.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only called inside a package the caller already confirmed with ShouldProcess.')]
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Values
    )

    $Content = [System.IO.File]::ReadAllText($Path)
    foreach ($Key in $Values.Keys) {
        $Escaped = ([string]$Values[$Key]).Replace("'", "''")
        $Content = $Content.Replace("##$($Key)_TEMPLATE", $Escaped)
    }
    $Tokens = $null
    $ParseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$Tokens, [ref]$ParseErrors)
    if ($ParseErrors) {
        throw "The script '$Path' does not parse after the template values were inserted: $($ParseErrors[0].Message)"
    }
    Set-Content -LiteralPath $Path -Value $Content -NoNewline -ErrorAction Stop
}
