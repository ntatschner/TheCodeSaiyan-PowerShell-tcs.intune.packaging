---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# New-IntuneWin32AppPackage

## SYNOPSIS
Creates an Intune Win32 application package (.intunewin file) from source files.

## SYNTAX

```
New-IntuneWin32AppPackage [-SourceFolder] <String> [-SetupFile] <String> [-OutputFolder] <String> [-Force]
 [[-IntuneWinAppUtilPath] <String>] [-AllowDownload] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The New-IntuneWin32AppPackage function wraps application source files and the main setup file
into an encrypted .intunewin package using Microsoft's IntuneWinAppUtil.exe tool.
This package
can then be uploaded to Microsoft Intune for Win32 app deployment.

## EXAMPLES

### EXAMPLE 1
```
New-IntuneWin32AppPackage -SourceFolder "C:\Apps\MyApp" -SetupFile "setup.exe" -OutputFolder "C:\Packages"
```

Creates an .intunewin package from the MyApp folder.

### EXAMPLE 2
```
New-IntuneWin32AppPackage -SourceFolder "C:\Apps\MyApp" -SetupFile "installer.msi" -OutputFolder "C:\Packages" -Force
```

Creates an .intunewin package and overwrites any existing package in the output folder.

## PARAMETERS

### -SourceFolder
The full path to the source folder containing the setup file and all dependency files.

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

### -SetupFile
The complete setup file name including extension (e.g., Setup.exe or Installer.msi).

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

### -OutputFolder
The full path to the output folder where the packaged .intunewin file will be saved.

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

### -Force
Switch to overwrite an existing .intunewin file if already present in the output folder.

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

### -IntuneWinAppUtilPath
The full path to the IntuneWinAppUtil.exe file.
When not specified, the per-user tool folder
(LocalApplicationData\tcs.intune.packaging) is used.
When the tool is missing there you are asked
before release v1.8.6 is downloaded (see AllowDownload).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Get-IntuneWinAppUtilPath)
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowDownload
Download IntuneWinAppUtil.exe to the per-user tool folder without asking when it is missing.
The download is refused unless it is signed by Microsoft (see Get-IntunePackagingTool).

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

### System.Management.Automation.PSCustomObject
### Name, FileName, SetupFile and UnencryptedContentSize from the package metadata (Detection.xml),
### and Path of the .intunewin file.
## NOTES
A missing source folder, setup file, output folder or tool, or a failure of IntuneWinAppUtil.exe,
is a terminating error.
An existing package without -Force is a non-terminating error and the
package is not created.
Both are reported to telemetry as failures.
The source folder should contain all files required for the application installation.

## RELATED LINKS

[https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)

