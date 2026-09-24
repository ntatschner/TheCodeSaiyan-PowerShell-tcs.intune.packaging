---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# Get-IntunePackagingTool

## SYNOPSIS
Downloads the Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe).

## SYNTAX

### Latest (Default)
```
Get-IntunePackagingTool -Path <String> [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DownloadTag
```
Get-IntunePackagingTool -Path <String> -DownloadTag <String> [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### DownloadUrl
```
Get-IntunePackagingTool -Path <String> -DownloadUrl <String> [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-IntunePackagingTool function downloads a release of the Microsoft Win32 Content Prep Tool
from GitHub (github.com/microsoft/Microsoft-Win32-Content-Prep-Tool), extracts it to a temporary
folder and copies IntuneWinAppUtil.exe to Path.
The downloaded archive and the extracted files
are removed afterwards.

By default the latest release is downloaded.
Use DownloadTag to pin a release, or DownloadUrl to
download a specific zip file.

## EXAMPLES

### EXAMPLE 1
```
Get-IntunePackagingTool -Path "C:\Tools"
```

Downloads the latest release and copies IntuneWinAppUtil.exe to C:\Tools.

### EXAMPLE 2
```
Get-IntunePackagingTool -Path "C:\Tools" -DownloadTag 'v1.8.6' -Force
```

Downloads release v1.8.6 and overwrites an existing C:\Tools\IntuneWinAppUtil.exe.

## PARAMETERS

### -Path
The folder that IntuneWinAppUtil.exe is copied to.
It is created when it does not exist.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
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

### -DownloadTag
The release tag to download, for example 'v1.8.6'.

```yaml
Type:String
Parameter Sets: DownloadTag
Aliases:
Required: True
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

### -DownloadUrl
The URL of a zip file that contains IntuneWinAppUtil.exe.
Used instead of the GitHub release
archive.

```yaml
Type:String
Parameter Sets: DownloadUrl
Aliases:
Required: True
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

### -Force
Overwrites IntuneWinAppUtil.exe when it already exists in Path.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
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

## OUTPUTS

### System.IO.FileInfo
### The copied IntuneWinAppUtil.exe file.
## NOTES

## RELATED LINKS

[https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)

