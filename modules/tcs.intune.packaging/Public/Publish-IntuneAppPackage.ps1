function Publish-IntuneAppPackage {
    <#
    .SYNOPSIS
        Checks whether an Intune Win32 application package can be published to Microsoft Intune.

    .DESCRIPTION
        The Publish-IntuneAppPackage function reads the application configuration JSON created by
        New-IntuneApplication, checks the Microsoft Graph connection and checks whether an application
        with the same display name already exists in Intune.

        Uploading the .intunewin content is not implemented yet: after the checks the function returns
        an error that says so. Use it to validate a package, or publish with another tool.

        Requires the Microsoft.Graph.Authentication and Microsoft.Graph.Devices.CorporateManagement
        modules and a connection made with Connect-MgGraph.

    .PARAMETER IntuneAppJSONPath
        The full path to the Intune application configuration JSON file.

    .PARAMETER IntuneWinPath
        The full path to the .intunewin package file.

    .PARAMETER Force
        Continue when an application with the same display name already exists.

    .PARAMETER NoTenantDetails
        Do not show the tenant connection details.

    .OUTPUTS
        None

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.json" -IntuneWinPath "C:\Packages\MyApp.intunewin"

        Checks the MyApp package against the connected tenant.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.json" -IntuneWinPath "C:\Packages\MyApp.intunewin" -Force -NoTenantDetails

        Checks the package without showing tenant details and without stopping on an existing application.

    .NOTES
        Requires connection to Microsoft Graph using Connect-MgGraph before running this function.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IntuneAppJSONPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IntuneWinPath,

        [switch]$Force,

        [switch]$NoTenantDetails
    )
    process {
        foreach ($Command in 'Get-MgContext', 'Get-MgDeviceAppManagementMobileApp') {
            if (-not (Get-Command -Name $Command -ErrorAction SilentlyContinue)) {
                throw "$Command is not available. Install the Microsoft.Graph.Authentication and Microsoft.Graph.Devices.CorporateManagement modules."
            }
        }
        $IntuneAppJSON = Get-Content -Path $IntuneAppJSONPath -Raw -ErrorAction Stop | ConvertFrom-Json
        $DisplayName = $IntuneAppJSON.ApplicationParameters.ApplicationName
        if ([string]::IsNullOrEmpty($DisplayName)) {
            $DisplayName = $IntuneAppJSON.ApplicationParameters.DisplayName
        }
        if ([string]::IsNullOrEmpty($DisplayName)) {
            throw "'$IntuneAppJSONPath' does not contain ApplicationParameters.ApplicationName."
        }

        # Check that the user is connected to Microsoft Graph
        $GraphContext = Get-MgContext
        if (-not $GraphContext) {
            throw 'You are not connected to Microsoft Graph. Connect with Connect-MgGraph first.'
        }
        if (-not $NoTenantDetails) {
            Write-Information -MessageData ("You're connected to Microsoft Graph as:`n`tUserName: $($GraphContext.Account)`n`t" +
                "Context scope: $($GraphContext.ContextScope)`n`tTenantId: $($GraphContext.TenantId)") -InformationAction Continue
        }

        # Check if the application already exists in Intune
        $IntuneApp = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$($DisplayName.Replace("'", "''"))'" -ErrorAction Stop
        if ($IntuneApp -and -not $Force) {
            throw "The application '$DisplayName' already exists in Intune. Use -Force to continue."
        }
        if ($IntuneApp) {
            Write-Warning "The application '$DisplayName' already exists in Intune."
        }

        if ($PSCmdlet.ShouldProcess($DisplayName, "Publish '$IntuneWinPath' to Intune")) {
            Write-Error -Exception ([System.NotImplementedException]::new('Uploading the package to Intune is not implemented yet. The package and connection checks passed.')) -Category NotImplemented
        }
    }
}
