---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://PENDIINGHOST/tcs.intune.packaging/docs/Get-MSIProperties.html
schema: 2.0.0
---

# Invoke-Executable

## SYNOPSIS
Invokes an executable file with specified parameters and captures its output.

## SYNTAX

```
Invoke-Executable [-FilePath] <String> [[-Arguments] <String>] [[-RedirectStandardOutput] <Boolean>]
 [[-RedirectStandardError] <Boolean>] [[-CreateNoWindow] <Boolean>] [[-UseShellExecute] <Boolean>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Invoke-Executable function runs an executable file with customizable process settings.
It provides control over standard output/error redirection, window creation, and shell execution.
The function waits for the process to complete and returns the exit code along with any captured output.

## EXAMPLES

### EXAMPLE 1
```
Invoke-Executable -FilePath "setup.exe" -Arguments "/silent /norestart"
```

Runs setup.exe with silent installation parameters.

### EXAMPLE 2
```
$result = Invoke-Executable -FilePath "C:\Tools\mytool.exe" -Arguments "-config test.json" -CreateNoWindow $false
```

Runs mytool.exe with a visible window and captures the result.

## PARAMETERS

### -FilePath
The file name or path of the executable to be invoked, including the extension.

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

### -Arguments
Arguments that will be passed to the executable.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RedirectStandardOutput
Specifies whether standard output should be redirected.
Default is $true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -RedirectStandardError
Specifies whether standard error output should be redirected.
Default is $true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateNoWindow
Specifies whether to create a new window for the executable.
Default is $true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseShellExecute
Specifies whether to use the operating system shell to start the process.
Default is $false.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

### Returns an object containing the exit code and any standard output/error from the executable.
## NOTES
When RedirectStandardOutput or RedirectStandardError is set to $true, UseShellExecute must be $false.

## RELATED LINKS
