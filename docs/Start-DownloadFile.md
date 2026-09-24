---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version:
schema: 2.0.0
---

# Start-DownloadFile

## SYNOPSIS
Downloads a file from a URL and saves it in a folder.

## SYNTAX

```
Start-DownloadFile [-URL] <String> [-Path] <String> [-Name] <String> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Start-DownloadFile function downloads the file at URL and saves it as Name in the folder Path.
The folder is created when it does not exist.
Download progress is shown by Invoke-WebRequest.
A failed download throws a terminating error and no partial file is left behind.

## EXAMPLES

### EXAMPLE 1
```
Start-DownloadFile -URL 'https://example.com/setup.msi' -Path 'C:\Temp\Downloads' -Name 'setup.msi'
```

Downloads setup.msi to C:\Temp\Downloads\setup.msi.

## PARAMETERS

### -URL
The URL of the file to download.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Path
The folder where the file is saved.
It is created when it does not exist.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 2Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Name
The file name to save the download as, including the file extension.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 3Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:wi
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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:cf
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

### None
## NOTES
Originally based on a function by Nickolaj Andersen (@NickolajA).
Since 0.3.0 the download uses Invoke-WebRequest instead of System.Net.WebClient events and no
longer creates global variables.

## RELATED LINKS
