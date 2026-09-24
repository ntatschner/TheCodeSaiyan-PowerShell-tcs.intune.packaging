[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
    Justification = 'Template: Intune-I-MainInstaller.ps1 passes -Uninstall for use in custom code.')]
param(
    [switch]$Uninstall
)
# --------------------------------------------------------------------------------------------
# Custom deployment script, run by Intune-I-MainInstaller.ps1.
# Add the install steps below and the uninstall steps in the if ($Uninstall) block.
# Files added to the package with -IncludedFiles are next to this script ($PSScriptRoot).
# Exit with 0 for success and any other code for failure.
# --------------------------------------------------------------------------------------------
if ($Uninstall) {
    # Uninstall steps
    exit 0
}

# Install steps
exit 0
