---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html
schema: 2.0.0
---

# New-IntuneApplication

## SYNOPSIS
Creates a new Intune application package with all necessary files and configurations.

## SYNTAX

```
New-IntuneApplication [-ApplicationName] <String> [-SourceFiles] <String[]> [-MainInstallerFileName] <String>
 [[-OutputFolder] <String>] [[-Description] <String>] [[-Publisher] <String>] [[-Version] <String>]
 [[-Developer] <String>] [[-owner] <String>] [[-notes] <String>] [[-LogoPath] <String>]
 [[-InstallFor] <String>] [[-RestartBehavior] <String>] [[-isFeatured] <Boolean>] [-InstallCommand] <String>
 [-UninstallCommand] <String> [[-RequirementRuleConfig] <Hashtable>] [-DetectionRuleConfig] <Hashtable>
 [-AssignmentType] <String> [[-AssignmentGroup] <String>] [[-FilterRuleType] <String>] [[-FilterRule] <String>]
 [-Publish] [[-IntuneToolsPath] <String>] [-Overwrite] [-NoJson] [-NoIntuneWin] [-NoCleanUp]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The New-IntuneApplication function creates a complete Intune application package by generating
the required folder structure, copying source files, creating detection scripts, and preparing
all necessary configuration files for deployment.

## EXAMPLES

### EXAMPLE 1
```
New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\*" -MainInstallerFileName "setup.exe"
```

Creates an Intune application package for MyApp in the current directory.

### EXAMPLE 2
```
New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\installer.msi", "C:\Source\config.xml" -MainInstallerFileName "installer.msi" -OutputFolder "C:\Packages" -Version "2.1" -LogoPath "C:\Images\logo.png"
```

Creates an Intune application package with specific version and logo.

## PARAMETERS

### -ApplicationName
The name of the application to be packaged.

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

### -SourceFiles
Array of paths to the source files that will be included in the application package.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MainInstallerFileName
The filename of the main installer executable or MSI file.

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

### -OutputFolder
The folder where the application package will be created.
Default is the current directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $($PWD.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
A description of the application.
Default includes ApplicationName, Publisher, Version, Developer, and notes.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: "# $ApplicationName`nPublisher: $Publisher`nVersion: $Version`nDeveloper: $Developer`n`n$notes"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publisher
The publisher of the application.
Default is the current username.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: $Env:USERNAME
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The version of the application.
Default is "1.0".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 1.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Developer
The developer of the application.
Default is the current username.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: $Env:USERNAME
Accept pipeline input: False
Accept wildcard characters: False
```

### -owner
The owner of the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -notes
Additional notes about the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogoPath
Path to the application logo image file.
Must be a PNG, JPG, or JPEG file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallFor
Specifies the installation context: "User" or "System".
Default is "System".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: System
Accept pipeline input: False
Accept wildcard characters: False
```

### -RestartBehavior
{{ Fill RestartBehavior Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: BasedOnReturnCode
Accept pipeline input: False
Accept wildcard characters: False
```

### -isFeatured
{{ Fill isFeatured Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallCommand
{{ Fill InstallCommand Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UninstallCommand
{{ Fill UninstallCommand Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequirementRuleConfig
{{ Fill RequirementRuleConfig Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DetectionRuleConfig
{{ Fill DetectionRuleConfig Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssignmentType
{{ Fill AssignmentType Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 19
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssignmentGroup
{{ Fill AssignmentGroup Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 20
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterRuleType
{{ Fill FilterRuleType Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterRule
{{ Fill FilterRule Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 22
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publish
{{ Fill Publish Description }}

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

### -IntuneToolsPath
{{ Fill IntuneToolsPath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 23
Default value: .\IntuneWinAppUtil.exe
Accept pipeline input: False
Accept wildcard characters: False
```

### -Overwrite
{{ Fill Overwrite Description }}

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

### -NoJson
{{ Fill NoJson Description }}

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

### -NoIntuneWin
{{ Fill NoIntuneWin Description }}

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

### -NoCleanUp
{{ Fill NoCleanUp Description }}

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

### PSObject containing information about the created application package.
## NOTES

## RELATED LINKS
