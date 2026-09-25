function Confirm-FolderOverwrite {
    <#
    .SYNOPSIS
        Asks whether an existing package folder may be deleted and recreated.

    .DESCRIPTION
        Wraps ShouldContinue so the APF commands share one prompt (and tests can answer it).
        Returns $true when the user agrees.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    $PSCmdlet.ShouldContinue("Overwrite the existing folder '$Path'? Warning: this recursively deletes all files in the folder.", 'Confirm overwrite')
}
