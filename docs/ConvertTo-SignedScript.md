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
 [[-TimestampServer] <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-SignedScript function signs PowerShell files (.ps1, .psm1, .psd1) with the code
signing certificate in a PFX file, using Set-AuthenticodeSignature and a DigiCert timestamp.
Each file is signed once; a file that fails is reported and the others are still signed.

This function needs Windows (Set-AuthenticodeSignature is only available there).

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-SignedScript -Path "C:\Scripts\MyScript.ps1" -CertificateFile "C:\Certs\MyCert.pfx" -Password (Read-Host -AsSecureString -Prompt 'PFX password')
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
The files must exist, have a .ps1, .psm1 or .psd1 extension and not be empty.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:FullName
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
Accept wildcard characters: False
```

### -CertificateFile
The path to the PFX certificate file used for signing.

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

### -Password
The password for the PFX certificate file as a SecureString.

```yaml
Type:SecureString
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

### -TimestampServer
The URL of the timestamp server.
Default is http://timestamp.digicert.com.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: Http://timestamp.digicert.com
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

### System.Management.Automation.Signature
### The signature result for each file, as returned by Set-AuthenticodeSignature.
## NOTES
The certificate must be valid for code signing and trusted on the system where the scripts will run.

## RELATED LINKS
