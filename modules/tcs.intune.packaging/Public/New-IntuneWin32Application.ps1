function New-IntuneWin32Application {
    <#
    .SYNOPSIS
        Prepares the properties of a new or cloned Win32 application in Microsoft Intune.

    .DESCRIPTION
        The New-IntuneWin32Application function builds the properties for a Win32 application in
        Microsoft Intune from its parameters or, with ExistingPackage, from an existing application that
        is cloned (parameters you specify win over the cloned values).

        Creating the application and uploading the .intunewin content through Microsoft Graph is not
        implemented yet: after building the properties the function returns an error that says so.

        Requires the Microsoft.Graph.Authentication and Microsoft.Graph.Devices.CorporateManagement
        modules and a connection made with Connect-MgGraph. ExistingPackage offers tab completion of
        the applications in the connected tenant.

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
        Whether the application is featured in the Company Portal.

    .PARAMETER ApplicableArchitectures
        The architecture the application applies to: x86, x64, arm or neutral. Default is x64.

    .PARAMETER MinimumFreeDiskSpaceInMB
        The minimum free disk space, in MB, required on the device.

    .PARAMETER MinimumMemoryInMB
        The minimum memory, in MB, required on the device.

    .PARAMETER MinimumNumberOfProcessors
        The minimum number of processors required on the device.

    .PARAMETER MinimumCpuSpeedInMHz
        The minimum CPU speed, in MHz, required on the device.

    .PARAMETER InstallExperienceRunAsAccount
        The account the installation runs as: system or user. Default is system.

    .PARAMETER InstallExperienceDeviceRestartBehavior
        The restart behaviour after installation: allow, basedOnReturnCode, suppress or force. Default is suppress.

    .PARAMETER MinimumSupportedWindowsRelease
        The minimum supported Windows release. Default is 22h2.

    .PARAMETER Rules
        Detection and requirement rules, for example created with New-IntuneWin32Rule.

    .PARAMETER IconFilePath
        The path to the application icon (PNG or JPG).

    .PARAMETER IntuneWinFilePath
        The path to the .intunewin package file.

    .PARAMETER ExistingPackage
        The existing application to clone, as "<DisplayName> | <Id>". Tab completion lists the
        applications in the connected tenant.

    .OUTPUTS
        None

    .EXAMPLE
        New-IntuneWin32Application -Name "MyApp" -Description "My Application" -Version "1.0.0" -Publisher "Contoso" -Owner "IT Admin" -Developer "Dev Team" -IntuneWinFilePath .\MyApp.intunewin

        Builds the properties for a new Win32 application.

    .EXAMPLE
        New-IntuneWin32Application -Version "2.0.0" -ExistingPackage "MyApp | 00000000-0000-0000-0000-000000000000" -IntuneWinFilePath .\MyApp.intunewin

        Builds the properties for a new version of an existing application.

    .NOTES
        Must be connected to Microsoft Graph with appropriate permissions before running this function.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NewPackage', SupportsShouldProcess)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Description,

        [Parameter(Mandatory)]
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

        [string]$Notes,

        [string]$PrivacyInformationUrl,

        [string]$InformationUrl,

        [bool]$IsFeatured,

        [ValidateSet("x86", "x64", "arm", "neutral")]
        [string]$ApplicableArchitectures = "x64",

        [int]$MinimumFreeDiskSpaceInMB,

        [int]$MinimumMemoryInMB,

        [int]$MinimumNumberOfProcessors,

        [int]$MinimumCpuSpeedInMHz,

        [ValidateSet("system", "user")]
        [string]$InstallExperienceRunAsAccount = "system",

        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$InstallExperienceDeviceRestartBehavior = "suppress",

        [string]$MinimumSupportedWindowsRelease = "22h2",

        [hashtable[]]$Rules,

        [string]$IconFilePath,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IntuneWinFilePath,

        [Parameter(Mandatory, ParameterSetName = 'CloneExistingPackage')]
        [ArgumentCompleter({
                param($CommandName, $ParameterName, $WordToComplete)
                $null = $CommandName, $ParameterName
                if (-not (Get-Command -Name 'Get-MgDeviceAppManagementMobileApp' -ErrorAction SilentlyContinue)) {
                    return
                }
                try {
                    Get-MgDeviceAppManagementMobileApp -All -Filter "NOT(startswith(Notes, 'PmpAppId:') or startswith(Notes, 'PmpUpdateId:'))" -Property DisplayName, CreatedDateTime, Id -ErrorAction Stop |
                        Group-Object -Property DisplayName |
                        ForEach-Object { $_.Group | Sort-Object -Property CreatedDateTime -Descending | Select-Object -First 1 } |
                        Where-Object { $_.DisplayName -like "$($WordToComplete.Trim("'"))*" } |
                        ForEach-Object { "'$($_.DisplayName) | $($_.Id)'" }
                }
                catch {
                    return
                }
            })]
        [ValidatePattern('\|')]
        [string]$ExistingPackage
    )

    begin {
        if (-not (Get-Command -Name 'Get-MgDeviceAppManagementMobileApp' -ErrorAction SilentlyContinue)) {
            throw 'Get-MgDeviceAppManagementMobileApp is not available. Install the Microsoft.Graph.Devices.CorporateManagement module and connect with Connect-MgGraph.'
        }
        if ($PSCmdlet.ParameterSetName -eq 'CloneExistingPackage') {
            $ExistingPackageSplit = $ExistingPackage.Split('|')
            $ExistingPackageID = $ExistingPackageSplit[-1].Trim()
            $ExistingPackageName = $ExistingPackageSplit[0].Trim()
            Write-Verbose "Retrieving existing package information for $ExistingPackageName ($ExistingPackageID)"
            try {
                $ClonePackage = Get-MgDeviceAppManagementMobileApp -MobileAppId $ExistingPackageID -ExpandProperty Assignments -ErrorAction Stop
            }
            catch {
                throw "Failed to retrieve existing package information for $($ExistingPackageName): $($_.Exception.Message)"
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
            Rules       = $Rules
            FilePath    = $IntuneWinFilePath
        }
        if ($PSCmdlet.ParameterSetName -eq 'CloneExistingPackage') {
            Write-Verbose "Cloning existing package information for $ExistingPackageName where parameters are not specified."
            $BoundNames = @($PSBoundParameters.Keys) + @(if ($PSBoundParameters.ContainsKey('Name')) { 'DisplayName' })
            foreach ($parameter in @($ClonePackage | Get-Member -MemberType Properties).Name) {
                if (($parameter -in @($PackageParams.Keys)) -and ($parameter -notin $BoundNames) -and -not [string]::IsNullOrEmpty($ClonePackage.$parameter)) {
                    Write-Verbose "Setting $parameter to $($ClonePackage.$parameter)"
                    $PackageParams[$parameter] = $ClonePackage.$parameter
                }
            }
        }

        if ($PSCmdlet.ShouldProcess([string]$PackageParams.DisplayName, 'Create Intune Win32 application')) {
            Write-Error -Exception ([System.NotImplementedException]::new('Creating the Win32 application in Intune is not implemented yet.')) -Category NotImplemented
        }
    }
}
