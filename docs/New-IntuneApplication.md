---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get
schema: 2.0.0
---

# New-IntuneApplication

## SYNOPSIS
Creates a new Intune application package with all necessary files and configurations.

## SYNTAX

```
New-IntuneApplication [-ApplicationName] <String> [-SourceFiles] <String[]> [-MainInstallerFileName] <String>
 [[-OutputFolder] <String>] [[-Description] <String>] [[-Publisher] <String>] [[-Version] <String>]
 [[-Developer] <String>] [[-Owner] <String>] [[-Notes] <String>] [[-LogoPath] <String>]
 [[-InstallFor] <String>] [[-RestartBehavior] <String>] [[-IsFeatured] <Boolean>] [-InstallCommand] <String>
 [-UninstallCommand] <String> [[-RequirementRuleConfig] <Hashtable>] [-DetectionRuleConfig] <Hashtable>
 [-AssignmentType] <String> [[-AssignmentGroup] <String>] [[-AssignmentIntent] <String>]
 [[-FilterRuleType] <String>] [[-FilterRule] <String>] [-Publish] [[-IntuneToolsPath] <String>]
 [-AllowDownload] [-Overwrite] [-NoJson] [-NoIntuneWin] [-NoCleanUp] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-IntuneApplication function creates a complete Intune application package by generating
the required folder structure, copying source files, creating detection scripts, and preparing
all necessary configuration files for deployment.

## EXAMPLES

### EXAMPLE 1
```
New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\MyApp" -MainInstallerFileName "setup.exe" -InstallCommand "setup.exe /S" -UninstallCommand "setup.exe /U" -DetectionRuleConfig @{ Type = 'File'; Path = 'C:\Program Files\MyApp' } -AssignmentType All-Devices
```

Creates MyApp.1.0.json and setup.intunewin in the current directory.

### EXAMPLE 2
```
New-IntuneApplication -ApplicationName "MyApp" -SourceFiles "C:\Source\installer.msi", "C:\Source\config.xml" -MainInstallerFileName "installer.msi" -OutputFolder "C:\Packages" -Version "2.1" -InstallCommand "msiexec /i installer.msi /qn" -UninstallCommand "msiexec /x installer.msi /qn" -DetectionRuleConfig @{ Type = 'MSI' } -AssignmentType User-Group -AssignmentGroup 'Intune-AG-MyApp-Available' -NoIntuneWin
```

Creates only the JSON configuration file for version 2.1.

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
The source files for the package: either one folder that contains all files, or one or more files
and folders.
When several are given they are copied (folders with their contents) to a temporary
staging folder, which is removed after the .intunewin package is created.

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
The file name of the main installer (for example setup.exe or installer.msi).
It must be one of
the source files, or be inside the source folder.

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
The existing folder where the JSON and .intunewin files are created.
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
Default is a Markdown summary of ApplicationName, Publisher,
Version, Developer and Notes.

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

### -Publisher
The publisher of the application.
Default is the current user name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: [Environment]::UserName
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
Default is the current user name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: [Environment]::UserName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner
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

### -Notes
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
Path to the application logo: a PNG or JPG image of at most 256x256 pixels.

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
The installation context: "User" or "System".
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
The device restart behaviour: basedOnReturnCode (default), allow, suppress or force.

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

### -IsFeatured
Whether the application is featured in the Company Portal.
Default is $false.

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
The command line that installs the application.

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
The command line that uninstalls the application.

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
A hashtable that describes the requirement rules; written to the JSON file.

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
A hashtable that describes the detection rules (for example from New-IntuneWin32Rule); written to the JSON file.

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
How the application is assigned: User-Group, Device-Group, All-Users or All-Devices.
Written to
the JSON file; Publish-IntuneAppPackage (and -Publish) assigns the app with it.

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
The group (ID or display name) the application is assigned to, for the User-Group and
Device-Group assignment types.

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

### -AssignmentIntent
The assignment intent: required (default), available or uninstall.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
Default value: Required
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterRuleType
Whether the assignment filter includes or excludes devices: Include or Exclude.
Use with FilterRule.

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

### -FilterRule
The name or ID of an existing Intune assignment filter.
Use with FilterRuleType.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 23
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publish
Publishes the package to Intune with Publish-IntuneAppPackage after creating it and assigns it
as set by AssignmentType, AssignmentGroup, AssignmentIntent and the filter parameters.
DetectionRuleConfig (and RequirementRuleConfig) must then be rules created with
New-IntuneWin32Rule.
With -Overwrite an existing app with the same name gets the package as a
new content version and its properties are updated.
The assignment settings are checked before
anything is built.

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
The path to IntuneWinAppUtil.exe.
When the file does not exist, the tool in the per-user tool
folder (LocalApplicationData\tcs.intune.packaging) is used; when it is missing there too you are
asked before release v1.8.6 is downloaded (see AllowDownload).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 24
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

### -Overwrite
Overwrite existing JSON and .intunewin files in OutputFolder.

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
Do not create the JSON configuration file.

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
Do not create the .intunewin package.

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
Keep the JSON file and .intunewin package after a successful -Publish (they are removed by default).

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
### JsonPath and IntuneWinPath of the created files ($null for files that were not created or were
### removed after publishing) and App, the published app when -Publish is used.
## NOTES

## RELATED LINKS
