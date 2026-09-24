---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# New-PackageJSON

## SYNOPSIS
Creates a package JSON metadata file for an application deployment.

## SYNTAX

```
New-PackageJSON [-PackageName] <String> [-Version] <String> [-Description] <String> [-Author] <String>
 [-SourceDirectory] <String> [-MainInstaller] <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-PackageJSON function writes a JSON file with package metadata (package name, version,
description, author, main installer file name and a comma-separated list of the names of all
items in the source directory) to "package-\<PackageName\>-v\<Version\>.json" in the source directory.
An existing metadata file with the same name is overwritten and is not listed in AllFiles.

## EXAMPLES

### EXAMPLE 1
```
New-PackageJSON -PackageName "MyApp" -Version "1.0.0" -Description "My Application" -Author "IT Team" -SourceDirectory "C:\Apps\MyApp" -MainInstaller "setup.exe"
```

Creates C:\Apps\MyApp\package-MyApp-v1.0.0.json.

## PARAMETERS

### -PackageName
The name of the application package.

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

### -Version
The version number of the package.

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

### -Description
A description of the package and its contents.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 3Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Author
The author or creator of the package.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 4Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -SourceDirectory
The directory that contains the application files.
The JSON file is written here.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 5Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -MainInstaller
The file name of the main installer executable or MSI file.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 6Default
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

### System.IO.FileInfo
### The JSON file that was written.
## NOTES

## RELATED LINKS
