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
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Publish-IntuneAppPackage function reads the application configuration JSON created by
New-IntuneApplication and publishes the .intunewin package with Microsoft Graph:

  - When no app with the same display name exists, it creates the Win32 app and uploads the
    package (see New-IntuneWin32Application).
  - When a Win32 app with the same display name exists, it stops unless -Force is used; with
    -Force it uploads the package as a new content version of the existing app.

The detection and requirement rules come from -Rules or, when omitted, from
DetectionRuleConfig and RequirementRuleConfig in the JSON file.
They must be rules created with
New-IntuneWin32Rule (hashtables with an '@odata.type').

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

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

Uploads setup.intunewin as a new content version of the existing MyApp app.

## PARAMETERS

### -IntuneAppJSONPath
The path to the application configuration JSON file created by New-IntuneApplication.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -IntuneWinPath
The path to the .intunewin package file.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 2Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Force
Upload the package as a new content version when an app with the same display name exists.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -NoTenantDetails
Do not show the tenant connection details.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Rules
Detection and requirement rules created with New-IntuneWin32Rule.
Overrides the rules in the JSON file.

```yaml
Type: Hashtable[]
Parameter Sets:   (All)
Aliases:
Required: False
Position: 3Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -PollIntervalSeconds
How often to check the upload and commit state.
Default is 5 seconds.

```yaml
Type:
Int32
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: 5
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -TimeoutSeconds
How long to wait for each upload or commit state.
Default is 600 seconds.

```yaml
Type:
Int32
Parameter Sets:   (All)
Aliases:
Required: False
Position: 5Default
Default value: None
Default value: 600
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:wi
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:cf
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type:ActionPreference
Parameter Sets:   (All)
Aliases:proga
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSCustomObject
### The Win32 app (id, displayName and committedContentVersion).
## NOTES
Requires connection to Microsoft Graph using Connect-MgGraph before running this function.

## RELATED LINKS

[New-IntuneWin32Application]()

