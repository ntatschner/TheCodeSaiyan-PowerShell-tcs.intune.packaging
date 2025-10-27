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
 [-SourceDirectory] <String> [-MainInstaller] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-PackageJSON function generates a JSON file containing package metadata including
package name, version, description, author, main installer filename, and a list of all files
in the source directory.
This metadata file can be used for tracking and deployment purposes.

## EXAMPLES

### EXAMPLE 1
```
New-PackageJSON -PackageName "MyApp" -Version "1.0.0" -Description "My Application" -Author "IT Team" -SourceDirectory "C:\Apps\MyApp" -MainInstaller "setup.exe"
```

Creates a JSON metadata file for MyApp in the source directory.

## PARAMETERS

### -PackageName
The name of the application package.

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

### -Version
The version number of the package.

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

### -Description
A description of the package and its contents.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Author
The author or creator of the package.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceDirectory
The directory path containing the application files to be inventoried.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MainInstaller
The filename of the main installer executable or MSI file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
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

### Creates a JSON file named "package-{PackageName}-v{Version}.json" in the source directory.
## NOTES
The function automatically inventories all files in the source directory and includes them in the JSON metadata.

## RELATED LINKS
