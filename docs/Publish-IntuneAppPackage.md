---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# Publish-IntuneAppPackage

## SYNOPSIS
Publishes an Intune Win32 application package to Microsoft Intune.

## SYNTAX

```
Publish-IntuneAppPackage [-IntuneAppJSONPath] <String> [-IntuneWinPath] <String> [-Force] [-NoTenantDetails]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Publish-IntuneAppPackage function uploads a Win32 application package (.intunewin file)
along with its configuration JSON to Microsoft Intune.
It checks for existing applications
and can optionally update them.

## EXAMPLES

### EXAMPLE 1
```
Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.json" -IntuneWinPath "C:\Packages\MyApp.intunewin"
```

Publishes the MyApp application to Intune.

### EXAMPLE 2
```
Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.json" -IntuneWinPath "C:\Packages\MyApp.intunewin" -Force
```

Publishes the MyApp application and overwrites if it already exists.

## PARAMETERS

### -IntuneAppJSONPath
The full path to the Intune application configuration JSON file.
The file must exist and be a valid file path.

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
The full path to the .intunewin package file.
The file must exist and be a valid file path.

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
Switch to force update of an existing application in Intune.
If not specified, the function will error if the application already exists.

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
Switch to suppress the display of tenant connection details.

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

### PSCustomObject containing information about the published application.
## NOTES
Requires connection to Microsoft Graph using Connect-MgGraph before running this function.
Requires the Microsoft.Graph.Intune and Microsoft.Graph.Authentication modules.

## RELATED LINKS
