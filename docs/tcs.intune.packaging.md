---
Module Name: tcs.intune.packaging
Module Guid: bfe12388-5f86-4da1-b08b-a439ff6f690c
Download Help Link: https://thecodesaiyan.io/modules/tcs.intune.packaging/
Help Version: 0.6.0
Locale: en-GB
---

# tcs.intune.packaging Module
## Description
Windows-only functions to build, package and deploy application and configuration packages for Microsoft Intune (Win32 apps, .intunewin packages and APF installer templates).

## tcs.intune.packaging Cmdlets
### [ConvertTo-SignedScript](ConvertTo-SignedScript.md)
Signs PowerShell script files with a PFX certificate.

### [Get-IntunePackagingTool](Get-IntunePackagingTool.md)
Downloads the Intune Content Prep Tools from the Microsoft Download Center and extracts the contents to the specified path.

### [Get-MSIProperties](Get-MSIProperties.md)
{{ Fill in the Synopsis }}

### [Invoke-Executable](Invoke-Executable.md)
Invokes an executable file with specified parameters and captures its output.

### [New-APFConfigDeployment](New-APFConfigDeployment.md)
{{ Fill in the Synopsis }}

### [New-APFDeployment](New-APFDeployment.md)
Creates an Application Packaging Framework (APF) deployment package for Intune.

### [New-ApplicationDeploymentGroups](New-ApplicationDeploymentGroups.md)
Creates security groups for application deployment in Intune.

### [New-IntuneApplication](New-IntuneApplication.md)
Creates a new Intune application package with all necessary files and configurations.

### [New-IntuneWin32Application](New-IntuneWin32Application.md)
Creates or clones a Win32 application in Microsoft Intune.

### [New-IntuneWin32AppPackage](New-IntuneWin32AppPackage.md)
Creates an Intune Win32 application package (.intunewin file) from source files.

### [New-PackageJSON](New-PackageJSON.md)
Creates a package JSON metadata file for an application deployment.

### [Publish-IntuneAppPackage](Publish-IntuneAppPackage.md)
Publishes an Intune Win32 application package to Microsoft Intune.

### [Start-DownloadFile](Start-DownloadFile.md)
Download a file from a given URL and save it in a specific location.

