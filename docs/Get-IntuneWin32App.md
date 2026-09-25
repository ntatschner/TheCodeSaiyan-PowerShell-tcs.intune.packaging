---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get
schema: 2.0.0
---

# Get-IntuneWin32App

## SYNOPSIS
Gets Win32 apps from Microsoft Intune.

## SYNTAX

### All (Default)
```
Get-IntuneWin32App [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Id
```
Get-IntuneWin32App -Id <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Name
```
Get-IntuneWin32App -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-IntuneWin32App function reads Win32 apps (win32LobApp) with Microsoft Graph v1.0:
  - With Id: GET /deviceAppManagement/mobileApps/{id}.
An app that is not a Win32 app is an error.
  - With Name: the Win32 apps whose display name is Name (exact match, not case-sensitive).
  - Without either: all Win32 apps in the tenant.

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.Read.All (or DeviceManagementApps.ReadWrite.All).

## EXAMPLES

### EXAMPLE 1
```
Get-IntuneWin32App -Name 'MyApp'
```

Gets the Win32 apps named MyApp.

### EXAMPLE 2
```
Get-IntuneWin32App | Select-Object id, displayName
```

Lists all Win32 apps.

## PARAMETERS

### -Id
The ID of the app.

```yaml
Type: String
Parameter Sets: Id
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The display name of the app.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
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
### The win32LobApp objects as returned by Microsoft Graph.
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get](https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get)

