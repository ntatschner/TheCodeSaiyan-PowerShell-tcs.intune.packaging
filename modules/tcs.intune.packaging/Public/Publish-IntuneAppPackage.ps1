#requires -Modules 'Microsoft.Graph.Intune', 'Microsoft.Graph.Authentication'
# Takes the .intunewin and configuration .json and publishes the application to Intune
function Publish-IntuneAppPackage {
    <#
    .SYNOPSIS
        Publishes an Intune Win32 application package to Microsoft Intune.

    .DESCRIPTION
        The Publish-IntuneAppPackage function uploads a Win32 application package (.intunewin file)
        along with its configuration JSON to Microsoft Intune. It checks for existing applications
        and can optionally update them.

    .PARAMETER IntuneAppJSONPath
        The full path to the Intune application configuration JSON file.
        The file must exist and be a valid file path.

    .PARAMETER IntuneWinPath
        The full path to the .intunewin package file.
        The file must exist and be a valid file path.

    .PARAMETER Force
        Switch to force update of an existing application in Intune.
        If not specified, the function will error if the application already exists.

    .PARAMETER NoTenantDetails
        Switch to suppress the display of tenant connection details.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.json" -IntuneWinPath "C:\Packages\MyApp.intunewin"
        
        Publishes the MyApp application to Intune.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.json" -IntuneWinPath "C:\Packages\MyApp.intunewin" -Force
        
        Publishes the MyApp application and overwrites if it already exists.

    .OUTPUTS
        PSCustomObject containing information about the published application.

    .NOTES
        Requires connection to Microsoft Graph using Connect-MgGraph before running this function.
        Requires the Microsoft.Graph.Intune and Microsoft.Graph.Authentication modules.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string]$IntuneAppJSONPath,
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string]$IntuneWinPath,
        [switch]$Force,
        [switch]$NoTenantDetails
    )
    
    begin {
        # Get the JSON object from the file
        $IntuneAppJSON = Get-Content -Path $IntuneAppJSONPath | ConvertFrom-Json
        # Check if the user is already connected to Intune
        $GraphContext = Get-MgContext
        if (-not $GraphContext) {
            Write-Error "You are not connected to Intune. Please connect to Intune using the Connect-MgGraph function"
            return
        }
        $TenantDetails = Get-MgOrganization
        if ($NoTenantDetails -eq $false) {
            Write-Warning "You're connected to MgGraph as:" +
            "`n`tUserName: $($GraphContext.Account)`n`t" +
            "In the Context Scope: $($GraphContext.ContextScope)`n`t" +
            "TenantId: $($TenantDetails.Id)`n`tTenantName: $($TenantDetails.DisplayName)"
            return
        }
    }
    process {
        # Check if the application already exists in Intune
        $IntuneApp = Get-MgGraphApplication -Filter "displayName eq '$($IntuneAppJSON.ApplicationParameters.DisplayName)'"
        if ($IntuneApp) {
            if ($Force) {
                Write-Warning "Application already exists in Intune. Forcing update of application"

            }
            else {
                Write-Error "Application already exists in Intune. Use the -Force switch to update the application"
                return
            }
        }
        else {
            
        }
        
    }
}
