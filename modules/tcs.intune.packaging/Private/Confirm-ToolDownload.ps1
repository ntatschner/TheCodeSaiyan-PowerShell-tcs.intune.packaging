function Confirm-ToolDownload {
    <#
    .SYNOPSIS
        Asks whether IntuneWinAppUtil.exe may be downloaded to a folder.

    .DESCRIPTION
        Wraps ShouldContinue so every packaging command asks the same question (and tests can answer
        it). Returns $true when the user agrees.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$Folder
    )

    $PSCmdlet.ShouldContinue("IntuneWinAppUtil.exe was not found in '$Folder'. Download it from Microsoft's GitHub repository (github.com/microsoft/Microsoft-Win32-Content-Prep-Tool) now?", 'Download IntuneWinAppUtil.exe')
}
