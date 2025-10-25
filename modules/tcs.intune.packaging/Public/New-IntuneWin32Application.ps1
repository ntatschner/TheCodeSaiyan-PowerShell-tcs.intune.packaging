#Requires -PSEdition Core
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Devices.CorporateManagement

function New-IntuneWin32Application {
    <#
    .SYNOPSIS
        Creates or clones a Win32 application in Microsoft Intune.

    .DESCRIPTION
        The New-IntuneWin32Application function creates a new Win32 application in Microsoft Intune or clones
        an existing application. It supports creating applications from scratch or duplicating existing ones
        with modified properties using Microsoft Graph API.

    .PARAMETER Name
        The display name of the application.

    .PARAMETER Description
        A description of the application and its purpose.

    .PARAMETER Version
        The version number of the application.

    .PARAMETER Publisher
        The publisher or vendor of the application.

    .PARAMETER Owner
        The owner or responsible party for the application.

    .PARAMETER Developer
        The developer or creator of the application.

    .PARAMETER Notes
        Additional notes or information about the application.

    .PARAMETER PrivacyInformationUrl
        URL to the application's privacy information or policy.

    .PARAMETER InformationUrl
        URL to additional information about the application.

    .PARAMETER IsFeatured
        Boolean indicating whether the application should be featured in the Company Portal.

    .EXAMPLE
        New-IntuneWin32Application -Name "MyApp" -Description "My Application" -Version "1.0.0" -Publisher "Contoso" -Owner "IT Admin" -Developer "Dev Team"
        
        Creates a new Win32 application in Intune.

    .EXAMPLE
        New-IntuneWin32Application -Name "MyApp v2" -Version "2.0.0" -CloneExistingPackage
        
        Clones an existing application with a new version.

    .NOTES
        Requires PowerShell Core and the Microsoft.Graph.Authentication and Microsoft.Graph.Devices.CorporateManagement modules.
        Must be connected to Microsoft Graph with appropriate permissions before running this function.
    #>
    [CmdletBinding()]
    [CmdletBinding(DefaultParameterSetName = 'NewPackage')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Name,
    
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Description,
        
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(Mandatory, ParameterSetName = 'CloneExistingPackage')]
        [version]$Version,
    
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Publisher,
    
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Owner,
    
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Developer,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Notes,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$PrivacyInformationUrl,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')] 
        [string]$InformationUrl,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [bool]$IsFeatured,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [ValidateSet("x86", "x64", "arm", "neutral")]
        [string]$ApplicableArchitectures = "x64",
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [int]$MinimumFreeDiskSpaceInMB,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [int]$MinimumMemoryInMB,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [int]$MinimumNumberOfProcessors,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [int]$MinimumCpuSpeedInMHz,
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [ValidateSet("system", "user")]
        [string]$InstallExperienceRunAsAccount = "system",
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$InstallExperienceDeviceRestartBehavior = "suppress",
    
        [Parameter(ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$MinimumSupportedWindowsRelease = "22h2",
    
        [hashtable[]]$Rules,
    
        [string]$IconFilePath,
    
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(Mandatory, ParameterSetName = 'CloneExistingPackage')]
        [ValidateScript({ Test-Path $_ })]
        [string]$IntuneWinFilePath,
    
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [ValidateSet([IntunePackages])]
        [string]$ExistingPackage
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'CloneExistingPackage') {
            Write-Verbose "Retrieving existing package information for $ExistingPackage"
            Write-Verbose "New Package will set selected package as its superseded source."
            Write-Verbose "Existing package will have its assignments copied and removed."
            $ExistingPackageSplit = $($ExistingPackage.Split('|'))
            $ExistingPackageID = $ExistingPackageSplit[-1].Trim()
            $ExistingPackageName = $ExistingPackageSplit[0].Trim()
            Write-Verbose "Existing package ID: $($ExistingPackageID)"
            try {
                $ClonePackage = Get-MGDeviceAppManagementMobileApp -ExpandProperty Assignments -MobileAppId $ExistingPackageID
                Write-Verbose "Successfully retrieved existing package information for $ExistingPackageName"
            }
            catch {
                Write-Error "Failed to retrieve existing package information for $ExistingPackageName"
                return
            }
        }
    }
    process {
        Write-Verbose "Defining package parameters"
        $PackageParams = @{
            DisplayName = $Name
            Description = $Description
            Publisher   = $Publisher
            Owner       = $Owner
            Developer   = $Developer
            Notes       = $Notes
            Version     = $Version
            $Rules      = $Rules
            FilePath    = $IntuneWinFilePath
        }
        if ($PSCmdlet.ParameterSetName -eq 'CloneExistingPackage') {
            Write-Verbose "Cloning existing package information for $ExistingPackageName where parameters are not specified."
            foreach ($parameter in $($ClonePackage | Get-Member -MemberType Properties).Name) {
                if (($parameter -in $PackageParams.Keys) -and ($parameter -notin $PSBoundParameters.Keys)) {
                    if ([string]::IsNullOrEmpty($($ClonePackage.$parameter)) -eq $false) {
                        Write-Verbose "Setting $parameter to $($ClonePackage.$parameter)"
                        $PackageParams[$parameter] = $ClonePackage.$parameter
                    }
                }
            }
        }
        
        Write-Verbose "Creating new package.."
        try {
            $NewPackage = New-MGBetaDeviceAppManagementMobileApp -
            Write-Verbose "Successfully created new package: $($NewPackage.DisplayName)"
        }
        catch {
            Write-Error "Failed to create new package: $Name"
            return
        }

    }
    end {

    }
}
