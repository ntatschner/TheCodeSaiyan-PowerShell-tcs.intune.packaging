---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-create
schema: 2.0.0
---

# New-IntuneWin32Application

## SYNOPSIS
Creates a Win32 application in Microsoft Intune and uploads its .intunewin package.

## SYNTAX

### NewPackage (Default)
```
New-IntuneWin32Application -Name <String> -Description <String> [-Version <Version>] -Publisher <String>
 [-Owner <String>] [-Developer <String>] [-Notes <String>] [-PrivacyInformationUrl <String>]
 [-InformationUrl <String>] [-IsFeatured <Boolean>] [-ApplicableArchitectures <String>]
 [-MinimumFreeDiskSpaceInMB <Int32>] [-MinimumMemoryInMB <Int32>] [-MinimumNumberOfProcessors <Int32>]
 [-MinimumCpuSpeedInMHz <Int32>] [-InstallExperienceRunAsAccount <String>]
 [-InstallExperienceDeviceRestartBehavior <String>] [-MinimumSupportedWindowsRelease <String>]
 -InstallCommandLine <String> -UninstallCommandLine <String> -Rules <Hashtable[]> [-ReturnCodes <Hashtable[]>]
 [-IconFilePath <String>] -IntuneWinFilePath <String> [-PollIntervalSeconds <Int32>] [-TimeoutSeconds <Int32>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CloneExistingPackage
```
New-IntuneWin32Application [-Name <String>] [-Description <String>] [-Version <Version>] [-Publisher <String>]
 [-Owner <String>] [-Developer <String>] [-Notes <String>] [-PrivacyInformationUrl <String>]
 [-InformationUrl <String>] [-IsFeatured <Boolean>] [-ApplicableArchitectures <String>]
 [-MinimumFreeDiskSpaceInMB <Int32>] [-MinimumMemoryInMB <Int32>] [-MinimumNumberOfProcessors <Int32>]
 [-MinimumCpuSpeedInMHz <Int32>] [-InstallExperienceRunAsAccount <String>]
 [-InstallExperienceDeviceRestartBehavior <String>] [-MinimumSupportedWindowsRelease <String>]
 [-InstallCommandLine <String>] [-UninstallCommandLine <String>] [-Rules <Hashtable[]>]
 [-ReturnCodes <Hashtable[]>] [-IconFilePath <String>] -IntuneWinFilePath <String> -ExistingPackage <String>
 [-PollIntervalSeconds <Int32>] [-TimeoutSeconds <Int32>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-IntuneWin32Application function creates a win32LobApp in Microsoft Intune with
Microsoft Graph (POST /deviceAppManagement/mobileApps), uploads the encrypted content of the
package (.intunewin file) to Azure Storage, commits it and sets the app's committed content version.
The app is returned when the upload is complete.

With ExistingPackage the properties of an existing Win32 app are copied (display name,
description, publisher, owner, developer, notes, URLs, command lines, rules, return codes,
install experience and requirements); parameters you specify win over the copied values.
Assignments and supersedence are not copied.

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
$detection = New-IntuneWin32Rule -RuleParentType detection -RuleType MSI -MSIPath .\setup.msi -AutoDetect $true
New-IntuneWin32Application -Name "MyApp" -Description "My Application" -Publisher "Contoso" -Owner "IT" -Developer "Dev Team" -InstallCommandLine 'msiexec /i "setup.msi" /qn' -UninstallCommandLine 'msiexec /x "setup.msi" /qn' -Rules $detection -IntuneWinFilePath .\setup.intunewin
```

Creates the app with an MSI detection rule and uploads setup.intunewin.

### EXAMPLE 2
```
New-IntuneWin32Application -ExistingPackage "MyApp | 00000000-0000-0000-0000-000000000000" -Version "2.0.0" -IntuneWinFilePath .\MyApp-2.0.intunewin
```

Creates a new app with the settings of an existing one and uploads the new package.

## PARAMETERS

### -Name
The display name of the application.

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

### -Description
A description of the application.

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

### -Version
The application version.
Graph v1.0 has no version property for Win32 apps, so the version is
added to the notes as "Version: \<version\>" unless the notes already contain it.

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publisher
The publisher of the application.

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

### -Owner
The owner of the application.

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

### -Developer
The developer of the application.

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

### -Notes
Notes for the application.

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
URL of the privacy statement.

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
URL with more information about the application.

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
Whether the application is featured in the Company Portal.

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
The architectures the app applies to: x86, x64, arm or neutral.
Default is x64.

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
The minimum free disk space, in MB, required to install the app.

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
The minimum physical memory, in MB, required to install the app.

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
The minimum number of processors required to install the app.

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
The minimum CPU speed, in MHz, required to install the app.

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
The context the app is installed in: system or user.
Default is system.

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
The restart behaviour: basedOnReturnCode, allow, suppress or force.
Default is basedOnReturnCode.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: BasedOnReturnCode
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumSupportedWindowsRelease
The minimum supported Windows release, for example 'Windows11_23H2'.
Not sent when omitted.

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

### -InstallCommandLine
The command line that installs the app, for example 'msiexec /i "setup.msi" /qn'.

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

### -UninstallCommandLine
The command line that uninstalls the app.

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

### -Rules
Detection and requirement rules created with New-IntuneWin32Rule.
At least one detection rule
is required for a new app.

```yaml
Type: Hashtable[]
Parameter Sets: NewPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Hashtable[]
Parameter Sets: CloneExistingPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnCodes
Return codes as hashtables with returnCode and type (success, failed, softReboot, hardReboot,
retry).
Default: 0 and 1707 success, 3010 softReboot, 1641 hardReboot, 1618 retry.

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
Path to a PNG or JPG icon for the app.

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
The path to the .intunewin package file.

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
The existing application to clone, as "\<DisplayName\> | \<Id\>" or just the app ID.
Tab completion
lists the Win32 apps in the connected tenant.

```yaml
Type: String
Parameter Sets: CloneExistingPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PollIntervalSeconds
How often to check the upload and commit state.
Default is 5 seconds.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSeconds
How long to wait for each upload or commit state.
Default is 600 seconds.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 600
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

### System.Management.Automation.PSCustomObject
### The created win32LobApp as returned by Microsoft Graph, with committedContentVersion set.
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-create](https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-create)

