function New-Win32Rule {
    <#
    .SYNOPSIS
        Creates detection or requirement rules for Intune Win32 applications.

    .DESCRIPTION
        The New-Win32Rule function generates rule objects that define detection logic or system requirements
        for Win32 applications in Microsoft Intune. It supports file/folder checks, registry checks,
        script-based detection, and MSI product code detection.

    .PARAMETER RuleParentType
        The parent type of rule to create: 'detection' or 'requirement'.

    .PARAMETER RuleType
        The type of rule to create: 'FileOrFolder', 'Registry', 'Script', or 'MSI'.

    .EXAMPLE
        New-Win32Rule -RuleParentType 'detection' -RuleType 'FileOrFolder' -Path "C:\Program Files\MyApp" -FileOrFolderName "MyApp.exe" -OperationType "exists"
        
        Creates a file existence detection rule.

    .EXAMPLE
        New-Win32Rule -RuleParentType 'detection' -RuleType 'Registry' -Path "HKLM:\Software\MyApp" -ValueName "Version" -OperationType "string" -Operator "equal" -ComparisonValue "1.0"
        
        Creates a registry value detection rule.

    .EXAMPLE
        New-Win32Rule -RuleParentType 'requirement' -RuleType 'Script' -ScriptFile "C:\Scripts\check.ps1"
        
        Creates a script-based requirement rule.

    .OUTPUTS
        Hashtable containing the rule configuration.

    .NOTES
        This function uses dynamic parameters based on the RuleType selected.
        Different rule types require different parameters to be specified.
    #>
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
        $RuleHashtable = @{}
        $RuleHashtable.Add("@odata.type", $RuleODataTypeHashtable[$RuleType])
        foreach ($P in $PSBoundParameters.Keys) {
            $RuleHashtable.Add($(ConvertTo-CamelCase -value $P), $PSBoundParameters[$P])
        }
        # Add parameters that have have default assigned and have not been overridden for each RuleType
        switch ($RuleType) {
            'file' {
                if (-not $RuleHashtable.ContainsKey('check32BitOn64System')) { $RuleHashtable.Add('check32BitOn64System', $false) }
                if ($RuleHashtable.operationType -eq 'exists' -and -Not $PSBoundParameters['ComparisonValue']) {
                    $RuleHashtable.Add('operator', 'equal')
                    $RuleHashtable.Add('ComparisonValue', $true)
                
                }
            }
            'registry' {
                if (-not $RuleHashtable.ContainsKey('path')) { $RuleHashtable.Add('path', $Path) }
                if (-not $RuleHashtable.ContainsKey('valueName')) { $RuleHashtable.Add('valueName', $ValueName) }
                if (-not $RuleHashtable.ContainsKey('registryOperationType')) { $RuleHashtable.Add('registryOperationType', $RegistryOperationType) }
            }
            'script' {
                $ScriptPath = $PSBoundParameters['ScriptPath']
                if ($RuleHashtable.ContainsKey('displayName') -and [string]::IsNullOrEmpty($RuleHashtable.displayName)) { $RuleHashtable.displayName = $(Split-Path -Path $ScriptPath -Leaf) }
                if (-not $RuleHashtable.ContainsKey('enforceSignatureCheck')) { $RuleHashtable.Add('enforceSignatureCheck', $false) }
                if (-not $RuleHashtable.ContainsKey('runAs32Bit')) { $RuleHashtable.Add('runAs32Bit', $false) }
                if (-not $RuleHashtable.ContainsKey('runAsAccount')) { $RuleHashtable.Add('runAsAccount', "system") }
                if ($RuleParentType -eq 'detection') {
                    $RuleHashtable.Add('operationType', 'notConfigured')
                    $RuleHashtable.Add('operator', 'notConfigured')
                }
                $RuleHashtable.scriptContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(
                            try {
                                Get-Content -Path $ScriptPath -ErrorAction Stop
                            }
                            catch {
                                Write-Error -Category ReadError -RecommendedAction "Verify path, and try again." -Message "Failed to read script content from $ScriptPath"
                                break
                            }
                        )))
                $RuleHashtable.Remove('ScriptPath')
            }
            'msi' {
                if (-not $RuleHashtable.ContainsKey('msiPath')) { $RuleHashtable.Add('msiPath', $MSIPath) }
                if (-not $RuleHashtable.ContainsKey('productCode')) { $RuleHashtable.Add('productCode', $ProductCode) }
                if (-not $RuleHashtable.ContainsKey('productVersionOperator')) { $RuleHashtable.Add('productVersionOperator', $ProductVersionOperator) }
                if (-not $RuleHashtable.ContainsKey('productVersion')) { $RuleHashtable.Add('productVersion', $ProductVersion) }
            }
        }
        # Remove Fields not needed for output
        $RuleHashtable.ruleType = $(ConvertTo-CamelCase -value $RuleParentType)
        $RuleHashtable.Remove('RuleParentType')
        $RuleHashtable.Remove('MSIPath')
        if (($RuleType -eq 'file' -or $RuleType -eq 'registry') -and ($FileOperationType -eq 'exists' -or $RegistryOperationType -eq 'exists')) {
            $RuleHashtable.Remove('Operator')
            $RuleHashtable.Remove('ComparisonValue')
        }
        if (($RuleType -eq 'msi' -and $AutoDetect -eq $true)) {
            $MSIInfo = Get-MSIProperties -Path $MSIPath
            $RuleHashtable.ProductCode = $MSIInfo.ProductCode
            $RuleHashtable.ProductVersion = $MSIInfo.ProductVersion
            $RuleHashtable.ProductVersionOperator = 'equal'
        }
        return $RuleHashtable 
    }
}
