---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version:
schema: 2.0.0
---

# Publish-IntuneAppPackage

## SYNOPSIS
Publishes an Intune Win32 application package (.intunewin and its JSON configuration) to Microsoft Intune.

## SYNTAX

```
Publish-IntuneAppPackage [-IntuneAppJSONPath] <String> [-IntuneWinPath] <String> [-Force] [-NoTenantDetails]
 [[-Rules] <Hashtable[]>] [[-PollIntervalSeconds] <Int32>] [[-TimeoutSeconds] <Int32>]
 [[-AssignmentType] <String>] [[-AssignmentGroup] <String>] [[-AssignmentIntent] <String>]
 [[-FilterRuleType] <String>] [[-FilterRule] <String>] [-NoAssignment] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Publish-IntuneAppPackage function reads the application configuration JSON created by
New-IntuneApplication and publishes the .intunewin package with Microsoft Graph:

  - When no app with the same display name exists, it creates the Win32 app and uploads the
    package (see New-IntuneWin32Application).
  - When a Win32 app with the same display name exists, it stops unless -Force is used; with
    -Force it uploads the package as a new content version of the existing app and then
    updates the app's properties from the JSON file (PATCH): display name, description,
    publisher, developer, owner, notes (with "Version: \<version\>"), featured, install and
    uninstall command lines, install experience, logo, rules, and the setup file and file name
    of the new package.

Then the app is assigned when an assignment type is set, either with -AssignmentType or by
AssignmentType in the JSON file (New-IntuneApplication writes it): to a group (User-Group or
Device-Group, by group ID or display name), all users or all devices, with the intent
required (default), available or uninstall, and optionally an assignment filter
(FilterRuleType Include or Exclude, FilterRule the filter name or ID).
Existing assignments are
kept; one to the same target is replaced.
Use -NoAssignment to skip this.
Assignments use the
Graph beta endpoint because assignment filters are only there.

The detection and requirement rules come from -Rules or, when omitted, from
DetectionRuleConfig and RequirementRuleConfig in the JSON file.
They must be rules created with
New-IntuneWin32Rule (hashtables with an '@odata.type').

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All (and Group.Read.All to assign to a
group by display name).

## EXAMPLES

### EXAMPLE 1
```
Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.0.json" -IntuneWinPath "C:\Packages\setup.intunewin"
```

Creates the MyApp Win32 app in Intune and uploads setup.intunewin.

### EXAMPLE 2
```
Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.1.json" -IntuneWinPath "C:\Packages\setup.intunewin" -Force -NoTenantDetails
```

Uploads setup.intunewin as a new content version of the existing MyApp app and updates its
properties from the JSON file.

### EXAMPLE 3
```
Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.0.json" -IntuneWinPath "C:\Packages\setup.intunewin" -AssignmentType User-Group -AssignmentGroup 'Intune-AG-MyApp-Available' -AssignmentIntent available
```

Creates the app and makes it available to the members of the Intune-AG-MyApp-Available group.

## PARAMETERS

### -IntuneAppJSONPath
The path to the application configuration JSON file created by New-IntuneApplication.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntuneWinPath
The path to the .intunewin package file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Upload the package as a new content version when an app with the same display name exists, and
update the app's properties from the JSON file.

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

### -NoTenantDetails
Do not show the tenant connection details.

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

### -Rules
Detection and requirement rules created with New-IntuneWin32Rule.
Overrides the rules in the JSON file.

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
Position: 4
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
Position: 5
Default value: 600
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssignmentType
How the app is assigned: User-Group, Device-Group, All-Users or All-Devices.
Overrides
AssignmentType in the JSON file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssignmentGroup
The group ID or display name for User-Group and Device-Group.
Overrides the JSON file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssignmentIntent
The assignment intent: required, available or uninstall.
Overrides the JSON file; default required.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterRuleType
Include or Exclude, for an assignment filter.
Overrides the JSON file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterRule
The name or ID of an existing Intune assignment filter.
Overrides the JSON file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoAssignment
Do not assign the app, even when the JSON file has an assignment type.

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
### The Win32 app (id, displayName and committedContentVersion), with Assignment (the assignment
### that was sent) when the app was assigned.
## NOTES
Requires connection to Microsoft Graph using Connect-MgGraph before running this function.

## RELATED LINKS

[New-IntuneWin32Application]()

