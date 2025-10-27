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
    FunctionsToExport    = '*'
    CmdletsToExport      = '*'
    VariablesToExport    = '*'
    AliasesToExport      = '*'
    # ScriptsToProcess ensures classes are loaded before the module
    ScriptsToProcess     = @('Classes\intune.package.ps1')
    PrivateData          = @{
        PSData = @{
            Tags                       = @('Intune', 'Packaging', 'Deployment', 'Applications')
            ExternalModuleDependencies = ''
            ReleaseNotes               = 'Added support for specifying group members for Available, Required, Test, and Phase1 groups in New-ApplicationDeploymentGroups.'
        } 
    } 
    HelpInfoURI          = 'https://PENDINGHOST/tcs.intune.packaging/'
}
