---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get
schema: 2.0.0
---

# New-APFDeployment

## SYNOPSIS
Creates an Application Packaging Framework (APF) deployment package for Intune.

## SYNTAX

```
New-APFDeployment [[-Name] <String>] [[-Version] <Version>] [[-Target] <String>] [[-InstallSwitches] <String>]
 [[-UninstallSwitches] <String>] [[-UninstallPath] <String>] [-Path] <String> [[-IncludedFiles] <String[]>]
 [[-DestinationFolder] <String>] [-CreateIntuneWinPackage] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-APFDeployment function creates a folder named after the application in DestinationFolder,
copies the installer and any additional files into it, adds the APF installer scripts from the
module's Application template and fills in config.installer.json and the detection script.
Optionally it also wraps the folder into a .intunewin package with IntuneWinAppUtil.exe.

For MSI files the name and version are read from the MSI when not supplied (Windows only).
For
EXE files the file name and file version are used.

When the application folder already exists you are asked before it is deleted and recreated;
when you decline, the folder is left unchanged and a warning is written.

The name is used as a folder name and is written into the detection script.
It must not be
'.' or '..', contain path separators, wildcard characters (\[ \]) or characters that Windows does
not allow in file names (\< \> : " | ?
*), or end with a space or a dot.

## EXAMPLES

### EXAMPLE 1
```
New-APFDeployment -Path "C:\Installers\MyApp.msi" -Name "MyApp" -Version "1.0.0.0"
```

Creates an APF deployment package for MyApp version 1.0.0.0 in the current directory.

### EXAMPLE 2
```
New-APFDeployment -Path "C:\Installers\Setup.exe" -InstallSwitches "/S" -UninstallSwitches "/U" -DestinationFolder C:\Packages -CreateIntuneWinPackage
```

Creates an APF deployment package with custom install and uninstall switches and a .intunewin package.

## PARAMETERS

### -Name
The name of the application.
It is written into the exported configuration files and used as the
folder name.
When omitted it is read from the installer file.

```yaml
Type: String
Parameter Sets: (All)
Aliases: ApplicationName, AppName

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The version of the application in the format x.x.x.x.
When omitted it is read from the installer file.

```yaml
Type: Version
Parameter Sets: (All)
Aliases: ApplicationVersion, AppVersion

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Target
The installation context: 'system' or 'user'.
Default is 'system'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: System
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallSwitches
The command-line switches used to install the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UninstallSwitches
The command-line switches used to uninstall the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UninstallPath
The path to the uninstall executable or file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
The path to the installer file (.msi or .exe).

```yaml
Type: String
Parameter Sets: (All)
Aliases: InstallerFile, SourceFile

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludedFiles
Paths to additional files to include in the package.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationFolder
The folder in which the application folder is created.
Default is the current directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: $PWD.Path
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateIntuneWinPackage
Also creates a .intunewin package in DestinationFolder.
IntuneWinAppUtil.exe is downloaded to the
per-user tool folder (LocalApplicationData\tcs.intune.packaging) after confirmation when it is missing.

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

### System.String
### Messages that describe where the package was created and which install commands to use.
## NOTES
Only MSI and EXE installer files are supported.

## RELATED LINKS
