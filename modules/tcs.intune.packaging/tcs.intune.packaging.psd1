@{
    ModuleVersion        = '0.2.10'
    CompatiblePSEditions = @('Desktop')
    GUID                 = 'bfe12388-5f86-4da1-b08b-a439ff6f690c'
    Author               = 'Nigel Tatschner'
    CompanyName          = 'TheCodeSaiyan'
    Copyright            = '(c) 2024 Nigel Tatschner. All rights reserved.'
    Description          = 'A set of functions designed to package and deploy Application packages to Microsoft Intune.'
    PowerShellVersion    = '5.1'
    RequiredModules      = @(
        @{ ModuleName     = 'tcs.core'
            ModuleVersion = '0.1.1'
        }
    )
    NestedModules        = @('tcs.intune.packaging.psm1')
    FunctionsToExport    = @(
        'Convert-ModuleNameAndReferences',
        'ConvertTo-SignedScript',
        'Get-IntunePackagingTool',
        'Get-MSIProperties',
        'Invoke-Executable',
        'New-APFConfigDeployment',
        'New-APFDeployment',
        'New-ApplicationDeploymentGroups',
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
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags                       = @('Intune', 'Packaging', 'Deployment', 'Applications')
            ExternalModuleDependencies = ''
            ReleaseNotes               = 'Added support for specifying group members for Available, Required, Test, and Phase1 groups in New-ApplicationDeploymentGroups.'
        }
    }
    HelpInfoURI          = 'https://thecodesaiyan.io/modules/tcs.intune.packaging/'
}
