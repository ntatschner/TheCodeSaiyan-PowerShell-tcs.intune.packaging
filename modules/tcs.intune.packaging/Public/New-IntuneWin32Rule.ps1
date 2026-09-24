function New-IntuneWin32Rule {
    <#
    .SYNOPSIS
        Creates detection or requirement rules for Intune Win32 applications.

    .DESCRIPTION
        The New-IntuneWin32Rule function generates rule objects that define detection logic or system requirements
        for Win32 applications in Microsoft Intune. It supports file/folder checks, registry checks,
        script-based detection, and MSI product code detection.

    .PARAMETER RuleParentType
        The parent type of rule to create: 'detection' or 'requirement'.

    .PARAMETER RuleType
        The type of rule to create: 'FileOrFolder', 'Registry', 'Script', or 'MSI'.
        The other parameters are dynamic and depend on RuleType:
          FileOrFolder  Path, FileOrFolderName, OperationType, Check32BitOn64BitSystem
          Registry      Path, KeyName, ValueName, Operator, DataType, Value
          Script        ScriptPath, RunAs32Bit, EnforceSignatureCheck; for requirement rules also
                        RunAsAccount, DisplayName, Operator, ComparisonValue, OperationType
          MSI           MSIPath, ProductCode, ProductVersionOperator, ProductVersion, AutoDetect
                        (AutoDetect reads the product code and version from the MSI; Windows only)

    .EXAMPLE
        New-IntuneWin32Rule -RuleParentType 'detection' -RuleType 'FileOrFolder' -Path "C:\Program Files\MyApp" -FileOrFolderName "MyApp.exe" -OperationType "exists"

        Creates a file existence detection rule.

    .EXAMPLE
        New-IntuneWin32Rule -RuleParentType 'detection' -RuleType 'Registry' -Path "HKLM:\Software" -KeyName "MyApp" -ValueName "Version" -Operator "equal" -DataType "version" -Value "1.0"

        Creates a registry value detection rule.

    .EXAMPLE
        New-IntuneWin32Rule -RuleParentType 'requirement' -RuleType 'Script' -ScriptPath "C:\Scripts\check.ps1" -RunAsAccount system

        Creates a script-based requirement rule.

    .OUTPUTS
        System.Collections.Hashtable
        The rule, with property names as used by the Microsoft Graph win32LobApp rule types.

    .NOTES
        This function uses dynamic parameters based on the RuleType selected.
        Different rule types require different parameters to be specified.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds an in-memory hashtable; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory, HelpMessage = 'The parent type of rule to create.')]
        [ValidateSet('detection', 'requirement')]
        [string]$RuleParentType,

        [Parameter(Mandatory, HelpMessage = 'The type of rule to create.')]
        [ValidateSet('FileOrFolder', 'Registry', 'Script', 'MSI')]
        [string]$RuleType
    )

    DynamicParam {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        $MultiSetParameters = @(
            @{Name = "Operator"; ParameterType = [string]; HelpMessage = "The comparison operator.";
                ValidateSet = @('equal', 'notEqual', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual')
            },
            @{Name = "ComparisonValue"; ParameterType = [string]; HelpMessage = "The value to compare against." },
            @{Name = "Path"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The path to the file or folder.";
                ValidateScript = { if (Test-Path -Path $_ -IsValid) { $true } else { throw "Path doesn't seem to be valid." } }
            },
            @{Name = "OperationType"; ParameterType = [string]; ValidateSet = @("notConfigured", "string", "dateTime", "integer", "float", "version", "boolean");
                HelpMessage = "The operation type for comparison."
            }
        )

        # Define parameter sets based on RuleType
        switch ($RuleType) {
            'FileOrFolder' {
                $fileParams = @(
                    @{Name = "FileOrFolderName"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The file or folder name." }
                    @{Name = "Check32BitOn64BitSystem"; ParameterType = [switch]; HelpMessage = "Expand 32bit variables on a 64bit system?" }
                )
                $FileSystemParamOperationType = $MultiSetParameters[3]
                $FileSystemParamOperationType.Mandatory = $true
                $FileSystemParamOperationType.ValidateSet = @("notConfigured", "exists", "modifiedDate", "createdDate", "version", "sizeInMB")
                $fileParams += $FileSystemParamOperationType

                $fileParams += $MultiSetParameters[2]
                foreach ($p in $fileParams) {
                    $param = $(New-DynamicParameter @p)
                    $paramDictionary.Add($param.Name, $param.Parameter)
                }
            }
            'Registry' {
                $registryParams = @(
                    @{Name = "Path"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The registry key path.";
                        ValidateScript = { if (Test-Path -Path $_ -IsValid) { $true } else { throw "Path doesn't seem to be valid." } }
                    }
                    @{Name = "KeyName"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The registry key name." }
                    @{Name = "ValueName"; ParameterType = [string]; HelpMessage = "The registry value name." }
                    @{Name = "Operator"; ParameterType = [string]; HelpMessage = "The registry comparison operator.";
                        ValidateSet = @('equal', 'notEqual', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual', 'exists', 'notExists')
                    }
                    @{Name = "DataType"; ParameterType = [string]; HelpMessage = "The registry value data type.";
                        ValidateSet = @('string', 'integer', 'version')
                    }
                    @{Name = "Value"; ParameterType = [string]; HelpMessage = "The registry value to compare against." }
                )
                foreach ($p in $registryParams) {
                    $param = $(New-DynamicParameter @p)
                    $paramDictionary.Add($param.Name, $param.Parameter)
                }
            }
            'Script' {
                $scriptParams = @(
                    @{Name = "ScriptPath"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The script path.";
                        ValidateScript = { if (Test-Path -Path $_ ) { $true } else { throw "Script path doesn't seem to be valid." } }
                    }
                    @{Name = "RunAs32Bit"; ParameterType = [switch]; HelpMessage = "Run script as 32-bit on 64-bit clients" }
                    @{Name = "EnforceSignatureCheck"; ParameterType = [switch]; HelpMessage = "Enforce script signature check" }

                )
                if ($RuleParentType -ne 'detection') {
                    $scriptParams += @{Name = "RunAsAccount"; ParameterType = [string]; Mandatory = $true; ValidateSet = @("system", "user");
                        HelpMessage = "The account to run the script as."
                    }
                    $scriptParams += @{Name = "DisplayName"; ParameterType = [string]; HelpMessage = "The display name of the script." }
                    $scriptParams += $MultiSetParameters[0, 1, 3]
                }
                foreach ($p in $scriptParams) {
                    $param = $(New-DynamicParameter @p)
                    $paramDictionary.Add($param.Name, $param.Parameter)
                }
            }
            'MSI' {
                $msiParams = @(
                    @{Name = "MSIPath"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The path to the MSI file.";
                        ValidateScript = { if (Test-Path -Path $_ -IsValid) { $true }else { throw "MSI path doesn't seem to be valid." } }
                    }
                    @{Name = "ProductCode"; ParameterType = [string]; HelpMessage = "The product code to detect." }
                    @{Name = "ProductVersionOperator"; ParameterType = [string]; HelpMessage = "The MSI operation type.";
                        ValidateSet = @('notConfigured', 'equal', 'notEqual', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual')
                    }
                    @{Name = "ProductVersion"; ParameterType = [string]; HelpMessage = "The value to compare against." }
                    @{Name = "AutoDetect"; ParameterType = [bool]; HelpMessage = "Detect the MSI properties automatically." }
                )
                foreach ($p in $msiParams) {
                    $param = $(New-DynamicParameter @p)
                    $paramDictionary.Add($param.Name, $param.Parameter)
                }
            }
        }
        return $paramDictionary
    }
    process {
        $RuleODataTypeHashtable = @{
            "fileorfolder" = "#microsoft.graph.win32LobAppFileSystemRule"
            "registry"     = "#microsoft.graph.win32LobAppRegistryRule"
            "script"       = "#microsoft.graph.win32LobAppPowerShellScriptRule"
            "msi"          = "#microsoft.graph.win32LobAppProductCodeRule"
        }
        # Dynamic parameters are not created as variables, so read everything from PSBoundParameters
        $CommonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        $RuleHashtable = @{}
        $RuleHashtable.Add("@odata.type", $RuleODataTypeHashtable[$RuleType])
        foreach ($P in $PSBoundParameters.Keys) {
            if ($P -in $CommonParameters -or $P -in 'RuleParentType', 'RuleType') {
                continue
            }
            $RuleHashtable[$(ConvertTo-CamelCase -Value $P)] = $PSBoundParameters[$P]
        }
        # Add parameters that have defaults and have not been overridden for each RuleType
        switch ($RuleType) {
            'FileOrFolder' {
                # Graph names the property check32BitOn64System
                $RuleHashtable['check32BitOn64System'] = [bool]$PSBoundParameters['Check32BitOn64BitSystem']
                $RuleHashtable.Remove('check32BitOn64BitSystem')
                if ($RuleHashtable['operationType'] -eq 'exists' -and -not $PSBoundParameters.ContainsKey('ComparisonValue')) {
                    $RuleHashtable['operator'] = 'notConfigured'
                }
            }
            'Script' {
                $ScriptPath = $PSBoundParameters['ScriptPath']
                if ($RuleParentType -ne 'detection' -and [string]::IsNullOrEmpty($RuleHashtable['displayName'])) {
                    $RuleHashtable['displayName'] = Split-Path -Path $ScriptPath -Leaf
                }
                $RuleHashtable['enforceSignatureCheck'] = [bool]$PSBoundParameters['EnforceSignatureCheck']
                $RuleHashtable['runAs32Bit'] = [bool]$PSBoundParameters['RunAs32Bit']
                if (-not $RuleHashtable.ContainsKey('runAsAccount')) {
                    $RuleHashtable['runAsAccount'] = 'system'
                }
                if ($RuleParentType -eq 'detection') {
                    $RuleHashtable['operationType'] = 'notConfigured'
                    $RuleHashtable['operator'] = 'notConfigured'
                }
                try {
                    $ScriptContent = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
                }
                catch {
                    throw "Failed to read script content from $($ScriptPath): $($_.Exception.Message)"
                }
                $RuleHashtable['scriptContent'] = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ScriptContent))
                $RuleHashtable.Remove('scriptPath')
            }
            'MSI' {
                if ($PSBoundParameters['AutoDetect'] -eq $true) {
                    $MSIInfo = Get-MSIProperty -Path $PSBoundParameters['MSIPath'] -ErrorAction Stop
                    $RuleHashtable['productCode'] = $MSIInfo.ProductCode
                    $RuleHashtable['productVersion'] = $MSIInfo.ProductVersion
                    $RuleHashtable['productVersionOperator'] = 'equal'
                }
                foreach ($Key in 'productCode', 'productVersionOperator', 'productVersion') {
                    if (-not $RuleHashtable.ContainsKey($Key)) {
                        $RuleHashtable[$Key] = $null
                    }
                }
                $RuleHashtable.Remove('msiPath')
                $RuleHashtable.Remove('autoDetect')
            }
        }
        $RuleHashtable['ruleType'] = ConvertTo-CamelCase -Value $RuleParentType
        if ($RuleType -in 'FileOrFolder', 'Registry' -and $RuleHashtable['operationType'] -in 'exists', 'notExists') {
            $RuleHashtable.Remove('comparisonValue')
        }
        return $RuleHashtable
    }
}
