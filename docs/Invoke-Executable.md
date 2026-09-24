---
external help file: tcs.intune.packaging-help.xml
Module Name: tcs.intune.packaging
online version: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
schema: 2.0.0
---

# Invoke-Executable

## SYNOPSIS
Runs an executable, waits for it to finish and returns its exit code and output.

## SYNTAX

```
Invoke-Executable [-FilePath] <String> [[-Arguments] <String>] [[-RedirectStandardOutput] <Boolean>]
 [[-RedirectStandardError] <Boolean>] [[-CreateNoWindow] <Boolean>] [[-UseShellExecute] <Boolean>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Invoke-Executable function starts an executable with System.Diagnostics.Process, waits for it
to exit and returns an object with the exit code.
When standard output or standard error is
redirected (the default), the text written to them is returned as well.
Redirected streams are
read while the process runs, so a process that writes a lot of output cannot block.

## EXAMPLES

### EXAMPLE 1
```
Invoke-Executable -FilePath "setup.exe" -Arguments "/silent /norestart"
```

Runs setup.exe with silent installation parameters and returns its exit code and output.

### EXAMPLE 2
```
$result = Invoke-Executable -FilePath "C:\Tools\mytool.exe" -Arguments "-config test.json" -CreateNoWindow $false -RedirectStandardOutput $false -RedirectStandardError $false
if ($result.ExitCode -ne 0) { throw "mytool failed with exit code $($result.ExitCode)" }
```

Runs mytool.exe in a visible window and checks the exit code.

## PARAMETERS

### -FilePath
The file name or path of the executable to run, including the extension.

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

### -Arguments
The command-line arguments passed to the executable, as a single string.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 2Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -RedirectStandardOutput
Whether standard output is captured and returned in the StandardOutput property.
Default is $true.
Must be $false when UseShellExecute is $true.

```yaml
Type:Boolean
Parameter Sets:   (All)
Aliases:
Required: False
Position: 3Default
Default value: None
Default value: True
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -RedirectStandardError
Whether standard error is captured and returned in the StandardError property.
Default is $true.
Must be $false when UseShellExecute is $true.

```yaml
Type:Boolean
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: True
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -CreateNoWindow
Whether the process is started without a new window.
Default is $true.

```yaml
Type:Boolean
Parameter Sets:   (All)
Aliases:
Required: False
Position: 5Default
Default value: None
Default value: True
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -UseShellExecute
Whether the operating system shell starts the process.
Default is $false.

```yaml
Type:Boolean
Parameter Sets:   (All)
Aliases:
Required: False
Position: 6Default
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

### System.Management.Automation.PSCustomObject
### ExitCode, StandardOutput and StandardError. The output properties are $null when the stream
### was not redirected.
## NOTES
When RedirectStandardOutput or RedirectStandardError is $true, UseShellExecute must be $false.

## RELATED LINKS
