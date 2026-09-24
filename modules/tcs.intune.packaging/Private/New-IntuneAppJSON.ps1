# Takes a hashtable of application parameters and returns the JSON document for an Intune application
function New-IntuneAppJSON {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds a JSON string; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$AppParams
    )

    # Copy the hashtable so the caller's splat is not changed
    $ApplicationParameters = @{}
    foreach ($Key in $AppParams.Keys) {
        $ApplicationParameters[$Key] = $AppParams[$Key]
    }
    # Split out the parameters for the .intunewin file
    $IntuneWinParams = @{
        "MainInstallerFileName" = $ApplicationParameters['MainInstallerFileName']
        "SourceFiles"           = $ApplicationParameters['SourceFiles']
        "OutputFolder"          = $ApplicationParameters['OutputFolder']
    }
    foreach ($Key in 'MainInstallerFileName', 'SourceFiles', 'OutputFolder') {
        $ApplicationParameters.Remove($Key)
    }

    [PSCustomObject]@{
        ApplicationParameters = $ApplicationParameters
        IntuneWinParameters   = $IntuneWinParams
    } | ConvertTo-Json -Depth 10
}
