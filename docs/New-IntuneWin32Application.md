---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html
schema: 2.0.0
---

# New-IntuneWin32Application

## SYNOPSIS
Creates or clones a Win32 application in Microsoft Intune.

## SYNTAX

### CloneExistingPackage
```
New-IntuneWin32Application [-Name <String>] [-Description <String>] -Version <Version> [-Publisher <String>]
 [-Owner <String>] [-Developer <String>] [-Notes <String>] [-PrivacyInformationUrl <String>]
 [-InformationUrl <String>] [-IsFeatured <Boolean>] [-ApplicableArchitectures <String>]
 [-MinimumFreeDiskSpaceInMB <Int32>] [-MinimumMemoryInMB <Int32>] [-MinimumNumberOfProcessors <Int32>]
 [-MinimumCpuSpeedInMHz <Int32>] [-InstallExperienceRunAsAccount <String>]
 [-InstallExperienceDeviceRestartBehavior <String>] [-MinimumSupportedWindowsRelease <String>]
 [-Rules <Hashtable[]>] [-IconFilePath <String>] -IntuneWinFilePath <String> [-ExistingPackage <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### NewPackage
```
New-IntuneWin32Application -Name <String> -Description <String> -Version <Version> -Publisher <String>
 -Owner <String> -Developer <String> [-Notes <String>] [-PrivacyInformationUrl <String>]
 [-InformationUrl <String>] [-IsFeatured <Boolean>] [-ApplicableArchitectures <String>]
 [-MinimumFreeDiskSpaceInMB <Int32>] [-MinimumMemoryInMB <Int32>] [-MinimumNumberOfProcessors <Int32>]
 [-MinimumCpuSpeedInMHz <Int32>] [-InstallExperienceRunAsAccount <String>]
 [-InstallExperienceDeviceRestartBehavior <String>] [-MinimumSupportedWindowsRelease <String>]
 [-Rules <Hashtable[]>] [-IconFilePath <String>] -IntuneWinFilePath <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The New-IntuneWin32Application function creates a new Win32 application in Microsoft Intune or clones
an existing application.
It supports creating applications from scratch or duplicating existing ones
with modified properties using Microsoft Graph API.

## EXAMPLES

### EXAMPLE 1
```
New-IntuneWin32Application -Name "MyApp" -Description "My Application" -Version "1.0.0" -Publisher "Contoso" -Owner "IT Admin" -Developer "Dev Team"
```

Creates a new Win32 application in Intune.

### EXAMPLE 2
```
New-IntuneWin32Application -Name "MyApp v2" -Version "2.0.0" -CloneExistingPackage
```

Clones an existing application with a new version.

## PARAMETERS

### -Name
The display name of the application.

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: NewPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
A description of the application and its purpose.

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: NewPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The version number of the application.

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publisher
The publisher or vendor of the application.

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: NewPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner
The owner or responsible party for the application.

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: NewPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Developer
The developer or creator of the application.

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: NewPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes
Additional notes or information about the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivacyInformationUrl
URL to the application's privacy information or policy.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InformationUrl
URL to additional information about the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsFeatured
Boolean indicating whether the application should be featured in the Company Portal.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicableArchitectures
{{ Fill ApplicableArchitectures Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: X64
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumFreeDiskSpaceInMB
{{ Fill MinimumFreeDiskSpaceInMB Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumMemoryInMB
{{ Fill MinimumMemoryInMB Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumNumberOfProcessors
{{ Fill MinimumNumberOfProcessors Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumCpuSpeedInMHz
{{ Fill MinimumCpuSpeedInMHz Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallExperienceRunAsAccount
{{ Fill InstallExperienceRunAsAccount Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: System
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallExperienceDeviceRestartBehavior
{{ Fill InstallExperienceDeviceRestartBehavior Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Suppress
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumSupportedWindowsRelease
{{ Fill MinimumSupportedWindowsRelease Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 22h2
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rules
{{ Fill Rules Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IconFilePath
{{ Fill IconFilePath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntuneWinFilePath
{{ Fill IntuneWinFilePath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExistingPackage
{{ Fill ExistingPackage Description }}

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Requires PowerShell Core and the Microsoft.Graph.Authentication and Microsoft.Graph.Devices.CorporateManagement modules.
Must be connected to Microsoft Graph with appropriate permissions before running this function.

## RELATED LINKS
