---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-update
schema: 2.0.0
---

# Set-IntuneWin32App

## SYNOPSIS
Updates the properties and rules of a Win32 app in Microsoft Intune.

## SYNTAX

### Parameters (Default)
```
Set-IntuneWin32App -Id <String> [-Name <String>] [-Description <String>] [-Publisher <String>]
 [-Owner <String>] [-Developer <String>] [-Notes <String>] [-Version <Version>]
 [-PrivacyInformationUrl <String>] [-InformationUrl <String>] [-IsFeatured <Boolean>]
 [-InstallCommandLine <String>] [-UninstallCommandLine <String>] [-InstallExperienceRunAsAccount <String>]
 [-InstallExperienceDeviceRestartBehavior <String>] [-Rules <Hashtable[]>] [-PassThru]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Json
```
Set-IntuneWin32App -Id <String> -JsonPath <String> [-PassThru] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-IntuneWin32App function updates an existing Win32 app with Microsoft Graph v1.0
(PATCH /deviceAppManagement/mobileApps/{id}).
Only the properties you give are changed.

With JsonPath the properties and rules come from the application JSON written by
New-IntuneApplication (display name, description, publisher, developer, owner, notes, version,
featured, install and uninstall command lines, install experience, logo and the detection and
requirement rules), as Publish-IntuneAppPackage -Force applies them.

Graph v1.0 has no version property for Win32 apps: Version is added to the notes as
"Version: \<version\>" (the current notes are read when Notes is not given).
Rules replace all
rules of the app and must contain a detection rule.
The package content is not changed; use
Publish-IntuneAppPackage -Force to upload a new package.

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Set-IntuneWin32App -Id $app.id -InstallCommandLine 'setup.exe /S /norestart' -Version '2.0.1'
```

Changes the install command line and records version 2.0.1 in the notes.

### EXAMPLE 2
```
Get-IntuneWin32App -Name 'MyApp' | Set-IntuneWin32App -JsonPath C:\Packages\MyApp.2.0.json -PassThru
```

Updates MyApp from the JSON file written by New-IntuneApplication.

## PARAMETERS

### -Id
The ID of the Win32 app.
Accepts pipeline input by property name (id), for example from
Get-IntuneWin32App.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -JsonPath
The application JSON file created by New-IntuneApplication.

```yaml
Type: String
Parameter Sets: Json
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The display name.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
The description.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publisher
The publisher.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner
The owner.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Developer
The developer.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes
The notes.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The version, added to the notes as "Version: \<version\>".

```yaml
Type: Version
Parameter Sets: Parameters
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
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InformationUrl
URL with more information about the app.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsFeatured
Whether the app is featured in the Company Portal.

```yaml
Type: Boolean
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallCommandLine
The command line that installs the app.

```yaml
Type: String
Parameter Sets: Parameters
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
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallExperienceRunAsAccount
The context the app is installed in: system or user.
Use with InstallExperienceDeviceRestartBehavior
or on its own (the restart behaviour is then basedOnReturnCode).

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallExperienceDeviceRestartBehavior
The restart behaviour: basedOnReturnCode, allow, suppress or force.

```yaml
Type: String
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rules
Detection and requirement rules created with New-IntuneWin32Rule.
They replace all rules of the app.

```yaml
Type: Hashtable[]
Parameter Sets: Parameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Returns the updated app.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
### The updated win32LobApp with -PassThru; otherwise nothing.
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-update](https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-update)

