---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html
schema: 2.0.0
---

# New-ApplicationDeploymentGroups

## SYNOPSIS
Creates security groups for application deployment in Intune.

## SYNTAX

```
New-ApplicationDeploymentGroups -ApplicationName <String[]> [-CreateGroups] [-CreateFile]
 [-Destination <Object>] [-AdminUnitId <String>] [-AvailableMembers <String[]>] [-RequiredMembers <String[]>]
 [-TestMembers <String[]>] [-Phase1Members <String[]>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-ApplicationDeploymentGroups function generates security group names for managing application deployments
in Intune.
It can create groups for different deployment scenarios (Available, Required, Test, Phase1) and
optionally create them in Azure AD or export them to a CSV file.

## EXAMPLES

### EXAMPLE 1
```
New-ApplicationDeploymentGroups -ApplicationName "Microsoft 365 Apps" -CreateGroups
```

Creates security groups in Azure AD for Microsoft 365 Apps deployment.

### EXAMPLE 2
```
New-ApplicationDeploymentGroups -ApplicationName "Adobe Reader", "Google Chrome" -CreateFile -Destination "C:\Output"
```

Generates a CSV file with group names for Adobe Reader and Google Chrome.

## PARAMETERS

### -ApplicationName
The name(s) of the application(s) for which to create deployment groups.
Multiple names can be provided.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateGroups
Switch to create the groups in Azure AD.

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

### -CreateFile
Switch to export the group list to a CSV file.

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

### -Destination
The destination folder path for the CSV file when using -CreateFile.
Must be a valid container path.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdminUnitId
The Administrative Unit ID in Azure AD where groups should be created.

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

### -AvailableMembers
Array of member IDs to add to the Available deployment groups.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequiredMembers
Array of member IDs to add to the Required deployment groups.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestMembers
Array of member IDs to add to the Test deployment groups.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Phase1Members
Array of member IDs to add to the Phase1 deployment groups.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

### PSObject containing the generated group information.
## NOTES

## RELATED LINKS

[https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html](https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html)

