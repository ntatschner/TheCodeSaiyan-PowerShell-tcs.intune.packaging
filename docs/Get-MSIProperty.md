---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# Get-MSIProperty

## SYNOPSIS
Reads the Property table of a Windows Installer (.msi) database.

## SYNTAX

```
Get-MSIProperty [-Path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-MSIProperty function opens an MSI database read-only with the WindowsInstaller.Installer
COM object and returns every row of its Property table (for example ProductName, ProductVersion,
ProductCode and Manufacturer) as the properties of a single object.

This function needs Windows, because it uses the Windows Installer COM object.
The alias Get-MSIProperties is kept for compatibility with earlier versions.

## EXAMPLES

### EXAMPLE 1
```
Get-MSIProperty -Path .\setup.msi | Select-Object ProductName, ProductVersion, ProductCode
```

Returns the product name, version and product code of setup.msi.

### EXAMPLE 2
```
Get-ChildItem -Path C:\Installers -Filter *.msi | Get-MSIProperty
```

Returns the properties of every MSI file in C:\Installers.

## PARAMETERS

### -Path
The path to the .msi file.
Accepts pipeline input, including FileInfo objects from Get-ChildItem.

```yaml
Type:String
Parameter Sets:   (All)
Aliases: Filename, MSIDbName, Database, Msi,FullName
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: True (ByPropertyName, ByValue)
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

### System.String
### System.IO.FileInfo
## OUTPUTS

### System.Management.Automation.PSCustomObject
## NOTES
Author: Nigel Tatschner

## RELATED LINKS
