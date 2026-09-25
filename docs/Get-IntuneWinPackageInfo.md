---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get
schema: 2.0.0
---

# Get-IntuneWinPackageInfo

## SYNOPSIS
Reads the metadata of a .intunewin package.

## SYNTAX

```
Get-IntuneWinPackageInfo [-Path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-IntuneWinPackageInfo function opens a .intunewin file (a zip archive) and reads
Metadata/Detection.xml, which IntuneWinAppUtil.exe writes: the setup file, the size of the
content before and after encryption, the tool version and, for MSI setup files, the MSI
details.
It works on every platform; the package is not extracted.

The encryption keys in Detection.xml are not returned.

## EXAMPLES

### EXAMPLE 1
```
Get-IntuneWinPackageInfo -Path .\setup.intunewin
```

Shows the setup file and content sizes of setup.intunewin.

### EXAMPLE 2
```
Get-ChildItem -Path C:\Packages -Filter *.intunewin | Get-IntuneWinPackageInfo | Format-Table SetupFile, UnencryptedContentSize
```

Lists the setup file of every package in C:\Packages.

## PARAMETERS

### -Path
The path to the .intunewin file.
Accepts pipeline input (for example from Get-ChildItem).

```yaml
Type: String
Parameter Sets: (All)
Aliases: FullName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
### Path, Name, FileName, SetupFile, UnencryptedContentSize, EncryptedContentSize, ToolVersion and
### MsiInfo ($null for other setup files).
## NOTES

## RELATED LINKS
