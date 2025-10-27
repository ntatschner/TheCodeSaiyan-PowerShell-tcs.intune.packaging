---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version:
schema: 2.0.0
---

# ConvertTo-SignedScript

## SYNOPSIS
Signs PowerShell script files with a PFX certificate.

## SYNTAX

```
ConvertTo-SignedScript [-Path] <String[]> [-CertificateFile] <String> [-Password] <SecureString>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-SignedScript function signs PowerShell script files (.ps1, .psm1, .psd1) using a specified PFX certificate file.
This function validates that the input files are PowerShell scripts and that the certificate file is valid before signing.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-SignedScript -Path "C:\Scripts\MyScript.ps1" -CertificateFile "C:\Certs\MyCert.pfx" -Password (ConvertTo-SecureString "MyPassword" -AsPlainText -Force)
```

Signs the specified PowerShell script with the provided certificate.

### EXAMPLE 2
```
Get-ChildItem -Path "C:\Scripts\*.ps1" | ConvertTo-SignedScript -CertificateFile "C:\Certs\MyCert.pfx" -Password $securePass
```

Signs all PowerShell scripts in the specified directory using pipeline input.

## PARAMETERS

### -Path
The path to one or more PowerShell script files to sign.
Accepts pipeline input.
Validates that files exist, have valid extensions (.ps1, .psm1, .psd1), and contain content.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FullName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -CertificateFile
The path to the PFX certificate file used for signing.
Must be a valid .pfx file that exists and contains data.

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

### -Password
The password for the PFX certificate file as a SecureString.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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

## NOTES
The certificate must be valid for code signing and trusted on the system where the scripts will run.

## RELATED LINKS
