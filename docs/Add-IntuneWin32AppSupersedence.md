---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/resources/intune-apps-mobileappsupersedence?view=graph-rest-beta
schema: 2.0.0
---

# Add-IntuneWin32AppSupersedence

## SYNOPSIS
Makes a Win32 app supersede (update or replace) other Win32 apps in Microsoft Intune.

## SYNTAX

```
Add-IntuneWin32AppSupersedence [-Id] <String> [-SupersededAppId] <String[]> [[-SupersedenceType] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Add-IntuneWin32AppSupersedence function adds supersedence relationships to the app Id: it
supersedes each app in SupersededAppId.
With SupersedenceType update (default) the new app is
installed over the old one; with replace the old app is uninstalled first.

It uses the Microsoft Graph beta action updateRelationships
(POST /deviceAppManagement/mobileApps/{id}/updateRelationships with
#microsoft.graph.mobileAppSupersedence), which is not available in Graph v1.0.
The app's
existing supersedence and dependency relationships are kept; a relationship to the same app is
replaced.

Requires the Microsoft.Graph.Authentication module and a connection made with
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

## EXAMPLES

### EXAMPLE 1
```
Add-IntuneWin32AppSupersedence -Id $newApp.id -SupersededAppId $oldApp.id -SupersedenceType replace
```

Makes the new app replace the old app (the old app is uninstalled first).

## PARAMETERS

### -Id
The ID of the new (superseding) app.
Accepts pipeline input by property name (id).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SupersededAppId
The IDs of the apps that the new app supersedes.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SupersedenceType
update (default) or replace.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Update
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

### None
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/graph/api/resources/intune-apps-mobileappsupersedence?view=graph-rest-beta](https://learn.microsoft.com/graph/api/resources/intune-apps-mobileappsupersedence?view=graph-rest-beta)

