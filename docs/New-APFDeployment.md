---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html
schema: 2.0.0
---

# New-APFDeployment

## SYNOPSIS
Creates an Application Packaging Framework (APF) deployment package for Intune.

## SYNTAX

```
New-APFDeployment [-Name <String>] [-Version <Version>] [-Target <String>] [-InstallSwitches <String>]
 [-UninstallSwitches <String>] [-UninstallPath <String>] -Path <Object> [-IncludedFiles <String[]>]
 [-DestinationFolder <String>] [-CreateIntuneWinPackage] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-APFDeployment function creates a deployment package that can be used with the Application Packaging Framework
to deploy applications to Intune-managed devices.
It generates the necessary configuration files and scripts
for deploying MSI or EXE installers.

## EXAMPLES

### EXAMPLE 1
```
New-APFDeployment -Path "C:\Installers\MyApp.msi" -Name "MyApp" -Version "1.0.0.0"
```

Creates an APF deployment package for MyApp version 1.0.0.0.

### EXAMPLE 2
```
New-APFDeployment -Path "C:\Installers\Setup.exe" -InstallSwitches "/S" -UninstallSwitches "/U"
```

Creates an APF deployment package with custom install and uninstall switches.

## PARAMETERS

### -Name
The name of the application.
If not provided, the script will attempt to extract it from the installer file.
Aliases: ApplicationName, AppName

```yaml
Type: String
Parameter Sets: (All)
Aliases: ApplicationName, AppName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The version of the application in the format x.x.x.x.
If not provided, the script will attempt to extract it from the installer file.
Aliases: ApplicationVersion, AppVersion

```yaml
Type: Version
Parameter Sets: (All)
Aliases: ApplicationVersion, AppVersion

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Target
The target context for the deployment: 'system' or 'user'.
Default is 'system'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: System
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallSwitches
The command-line switches to use when installing the application.

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

### -UninstallSwitches
The command-line switches to use when uninstalling the application.

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

### -UninstallPath
The path to the uninstall executable or file.

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

### -Path
The path to the installer file (.msi or .exe).
This is a mandatory parameter.
Aliases: InstallerFile, SourceFile

```yaml
Type: Object
Parameter Sets: (All)
Aliases: InstallerFile, SourceFile

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludedFiles
Paths to any additional files that need to be included in the installation package.

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

### -DestinationFolder
The folder where the files will be copied to.
Default is the current directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PWD.Path
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateIntuneWinPackage
Create a Intune package for the application.
Default is false.

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

## NOTES
Only MSI and EXE installer files are supported.

## RELATED LINKS

[https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html](https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html)

