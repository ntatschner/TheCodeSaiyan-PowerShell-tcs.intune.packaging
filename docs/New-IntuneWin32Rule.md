---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# New-IntuneWin32Rule

## SYNOPSIS
Creates detection or requirement rules for Intune Win32 applications.

## SYNTAX

```
New-IntuneWin32Rule [-RuleParentType] <String> [-RuleType] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-IntuneWin32Rule function generates rule objects that define detection logic or system requirements
for Win32 applications in Microsoft Intune.
It supports file/folder checks, registry checks,
script-based detection, and MSI product code detection.

## EXAMPLES

### EXAMPLE 1
```
New-IntuneWin32Rule -RuleParentType 'detection' -RuleType 'FileOrFolder' -Path "C:\Program Files\MyApp" -FileOrFolderName "MyApp.exe" -OperationType "exists"
```

Creates a file existence detection rule.

### EXAMPLE 2
```
New-IntuneWin32Rule -RuleParentType 'detection' -RuleType 'Registry' -Path "HKLM:\Software" -KeyName "MyApp" -ValueName "Version" -Operator "equal" -DataType "version" -Value "1.0"
```

Creates a registry value detection rule.

### EXAMPLE 3
```
New-IntuneWin32Rule -RuleParentType 'requirement' -RuleType 'Script' -ScriptPath "C:\Scripts\check.ps1" -RunAsAccount system
```

Creates a script-based requirement rule.

## PARAMETERS

### -RuleParentType
The parent type of rule to create: 'detection' or 'requirement'.

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

### -RuleType
The type of rule to create: 'FileOrFolder', 'Registry', 'Script', or 'MSI'.
The other parameters are dynamic and depend on RuleType:
  FileOrFolder  Path, FileOrFolderName, OperationType, Operator, ComparisonValue,
                Check32BitOn64BitSystem
  Registry      Path (key path), KeyName (optional sub key), ValueName, Operator (exists,
                notExists or a comparison), DataType (string, integer, version) and Value for
                comparisons, Check32BitOn64BitSystem
  Script        ScriptPath, RunAs32Bit, EnforceSignatureCheck; for requirement rules also
                RunAsAccount, DisplayName, Operator, ComparisonValue, OperationType
  MSI           MSIPath, ProductCode, ProductVersionOperator, ProductVersion, AutoDetect
                (AutoDetect reads the product code and version from the MSI; Windows only).
                MSI rules can only be detection rules.

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

### System.Collections.Hashtable
### The rule, with property names as used by the Microsoft Graph win32LobApp rule types.
## NOTES
This function uses dynamic parameters based on the RuleType selected.
Different rule types require different parameters to be specified.

## RELATED LINKS
