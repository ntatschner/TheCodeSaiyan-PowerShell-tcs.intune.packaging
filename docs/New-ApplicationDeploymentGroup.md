---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# New-ApplicationDeploymentGroup

## SYNOPSIS
Generates, and optionally creates, the Entra ID security groups used to deploy an application with Intune.

## SYNTAX

```
New-ApplicationDeploymentGroup -ApplicationName <String[]> [-CreateGroups] [-CreateFile]
 [-Destination <String>] [-AdminUnitId <String>] [-AvailableMembers <String[]>] [-RequiredMembers <String[]>]
 [-TestMembers <String[]>] [-Phase1Members <String[]>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-ApplicationDeploymentGroup function builds four group names for each application:
  Intune-AG-\<Name\>-Available, Intune-AG-\<Name\>-Required, Intune-App-\<Name\>-Test and
  Intune-App-\<Name\>-Phase1
where \<Name\> is the application name in title case without spaces.

By default the group list is returned.
With -CreateGroups the groups are created in Entra ID
(existing groups are skipped), optionally added to an administrative unit and given members.
With -CreateFile the list is also exported to Application-Groups.csv in Destination.

Creating groups needs the Microsoft.Entra module (Get-EntraGroup, New-EntraGroup,
Add-EntraGroupMember) and, for -AdminUnitId, Microsoft.Graph.Identity.DirectoryManagement.
Connect first with Connect-Entra or Connect-MgGraph.

The alias New-ApplicationDeploymentGroups is kept for compatibility with earlier versions.

## EXAMPLES

### EXAMPLE 1
```
New-ApplicationDeploymentGroup -ApplicationName "Microsoft 365 Apps"
```

Returns the four group names for Microsoft 365 Apps, for example Intune-AG-Microsoft365Apps-Available.

### EXAMPLE 2
```
New-ApplicationDeploymentGroup -ApplicationName "Microsoft 365 Apps" -CreateGroups -TestMembers '00000000-0000-0000-0000-000000000001'
```

Creates the security groups in Entra ID and adds one member to the Test group.

### EXAMPLE 3
```
New-ApplicationDeploymentGroup -ApplicationName "Adobe Reader", "Google Chrome" -CreateFile -Destination "C:\Output"
```

Returns the group names for Adobe Reader and Google Chrome and writes them to C:\Output\Application-Groups.csv.

## PARAMETERS

### -ApplicationName
The name(s) of the application(s) for which to create deployment groups.
Multiple names can be provided.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
Required: True
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

### -CreateGroups
Create the groups in Entra ID.

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

### -CreateFile
Export the group list to Application-Groups.csv in Destination.

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

### -Destination
The folder for Application-Groups.csv when using -CreateFile.
Must be an existing folder.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
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

### -AdminUnitId
The ID of the Entra ID administrative unit that new groups are added to.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
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

### -AvailableMembers
Object IDs of the members to add to the Available groups.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
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

### -RequiredMembers
Object IDs of the members to add to the Required groups.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
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

### -TestMembers
Object IDs of the members to add to the Test groups.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
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

### -Phase1Members
Object IDs of the members to add to the Phase1 groups.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
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
### One object per group (Name, GroupName, GroupDescription) when -CreateGroups is not used.
## NOTES

## RELATED LINKS
