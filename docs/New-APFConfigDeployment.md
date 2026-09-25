---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-get
schema: 2.0.0
---

# New-APFConfigDeployment

## SYNOPSIS
Creates an APF (Application Packaging Framework) configuration deployment package for Intune.

## SYNTAX

```
New-APFConfigDeployment [-ConfigurationType] <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The New-APFConfigDeployment function creates a folder named after the deployment in
DestinationFolder, copies the matching APF installer templates into it and fills in
config.installer.json and the detection script.
Optionally it also wraps the folder into an
Intune package ("\<Name\>.intunewin" in DestinationFolder).

The parameters available depend on ConfigurationType (they are dynamic parameters):
  - All types: Name, Version, DestinationFolder, CreateIntuneWinPackage.
  - Registry: IncludedFiles, RegistryValue, Target.
  - PowerShellProfiles and Files: Files, FilesDirectoryName.
  - Script-OS and WindowsFeature: IncludedFiles.
  - StandAlone-Exe: Path, IncludedFiles, CLIApp.
  - Script-App and Script-User: Path (the deployment script), IncludedFiles.
  - Custom: IncludedFiles, Target.
  - Standalone-Application: Path, IncludedFiles, LauncherName, LauncherRelativePath.

Dynamic parameters:
  Name                    The name of the deployment; written into the configuration files and
                          used as the folder name.
  Version                 The version of the deployment (x.x.x.x).
  Path                    The main file (StandAlone-Exe), the file or folder of a standalone
                          application (Standalone-Application) or the PowerShell deployment
                          script (Script-App, Script-User).
  DestinationFolder       Where the package folder is created.
Default is the current directory.
  CreateIntuneWinPackage  Also create a .intunewin package.
  IncludedFiles           Additional files or folders to include in the package.
  RegistryValue           One registry entry in the format of the registry CSV columns:
                          "RegistryPath,KeyName,ValueName,ValueType,ValueData,State", for example
                          "HKLM:\Software,MySoftware,MyValue,String,MyData,ADD".
State is ADD,
                          MODIFY or REMOVE.
More entries can be added to the generated
                          "\<Name\>_Registry.csv" file.
Any failed entry fails the whole deployment.
  Target                  'System' (default) or 'User'.
  LauncherName            The file that launches a standalone application.
  LauncherRelativePath    The relative path of the launcher inside the included files.
  CLIApp                  $true when a standalone executable is a command-line tool; it is then
                          installed to the APF bin folder that is added to PATH.
  Files                   The files to deploy (PowerShellProfiles and Files).
  FilesDirectoryName      The name of the directory the files are deployed to.

When the package folder already exists you are asked before it is deleted and recreated; when
you decline, that deployment is skipped with a warning.
The package folder is always a
subfolder of DestinationFolder: Name must not be '.' or '..', contain path separators, wildcard
characters (\[ \]) or characters that Windows does not allow in file names (\< \> : " | ?
*), or
end with a space or a dot.
Name, Version and the other dynamic parameters can be bound from the
pipeline by property name, one package per input object.

Script-App, Script-User and Custom packages use the "script" template: the main installer runs
the pre-install script, the deployment script and the post-install script (each with -Uninstall
for the uninstall command) and saves the configuration that the detection script checks.
  - Script-App runs your script in the system context.
  - Script-User runs your script in the user context (assign the Intune app to run as user).
  - Custom adds a placeholder deployment script, Intune-Custom.ps1, for you to complete.

## EXAMPLES

### EXAMPLE 1
```
New-APFConfigDeployment -ConfigurationType Registry -Name "My Settings" -Version "1.0.0.0" -RegistryValue "HKLM:\Software,MySoftware,MyValue,String,MyData,ADD"
```

Creates a registry deployment package with one registry entry.

### EXAMPLE 2
```
New-APFConfigDeployment -ConfigurationType Files -Name "My Files" -Version "1.0.0.0" -Files "C:\file1.txt", "C:\file2.txt" -FilesDirectoryName "MyFiles"
```

Creates a package that deploys two files to the MyFiles directory.

### EXAMPLE 3
```
New-APFConfigDeployment -ConfigurationType StandAlone-Exe -Name "MyApp" -Version "1.2.3.4" -Path "C:\path\to\myapp.exe" -CLIApp $true
```

Creates a package that installs myapp.exe as a command-line tool.

## PARAMETERS

### -ConfigurationType
The type of configuration package to create: Registry, PowerShellProfiles, Files, Script-OS,
Script-App, Script-User, StandAlone-Exe, Standalone-Application, WindowsFeature or Custom.
Script-App, Script-User and Custom build a script package; see the description.

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
The generated installer scripts run on Windows devices managed by Intune.

## RELATED LINKS
