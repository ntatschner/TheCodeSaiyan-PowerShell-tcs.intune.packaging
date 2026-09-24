@{
    RootModule           = 'tcs.intune.packaging.psm1'
    ModuleVersion        = '0.4.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    GUID                 = 'bfe12388-5f86-4da1-b08b-a439ff6f690c'
    Author               = 'Nigel Tatschner'
    CompanyName          = 'TheCodeSaiyan'
    Copyright            = '(c) 2024 Nigel Tatschner. All rights reserved.'
    Description          = 'Windows-only functions to build, package and deploy application and configuration packages for Microsoft Intune (Win32 apps, .intunewin packages and APF installer templates).'
    PowerShellVersion    = '5.1'
    RequiredModules      = @(
        @{ ModuleName = 'tcs.core'; ModuleVersion = '0.3.0' }
    )
    FunctionsToExport    = @(
        'ConvertTo-SignedScript',
        'Get-IntunePackagingTool',
        'Get-MSIProperty',
        'Invoke-Executable',
        'New-APFConfigDeployment',
        'New-APFDeployment',
        'New-ApplicationDeploymentGroup',
        'New-IntuneApplication',
        'New-IntuneWin32AppPackage',
        'New-IntuneWin32Application',
        'New-IntuneWin32Rule',
        'New-PackageJSON',
        'Publish-IntuneAppPackage',
        'Start-DownloadFile'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @('Get-MSIProperties', 'New-ApplicationDeploymentGroups')
    PrivateData          = @{
        PSData = @{
            Tags         = @('Intune', 'Packaging', 'Deployment', 'Applications', 'Win32', 'IntuneWin', 'Windows', 'PSEdition_Desktop', 'PSEdition_Core')
            ProjectUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.intune.packaging'
            LicenseUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.intune.packaging/blob/main/LICENSE'
            ReleaseNotes = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.intune.packaging/blob/main/CHANGELOG.md'
        }
    }
    HelpInfoURI          = 'https://thecodesaiyan.io/modules/tcs.intune.packaging/'
}
