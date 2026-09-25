---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-delete
schema: 2.0.0
---

# Remove-IntuneWin32App

## SYNOPSIS
Deletes a Win32 app from Microsoft Intune.

## SYNTAX

```
Remove-IntuneWin32App [-Id] <String[]> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Remove-IntuneWin32App function reads the app first and only deletes it
(DELETE /deviceAppManagement/mobileApps/{id}) when it is a Win32 app (win32LobApp).
You are asked
to confirm each app; use -Confirm:$false to skip that and -WhatIf to see what would be deleted.

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Remove-IntuneWin32App -Id '00000000-0000-0000-0000-000000000000' -WhatIf
```

Shows which app would be deleted.

### EXAMPLE 2
```
Get-IntuneWin32App -Name 'MyApp (old)' | Remove-IntuneWin32App
```

Deletes the Win32 apps named "MyApp (old)" after confirmation.

## PARAMETERS

### -Id
The ID of the app.
Accepts pipeline input, for example from Get-IntuneWin32App.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### None
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-delete](https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-delete)

