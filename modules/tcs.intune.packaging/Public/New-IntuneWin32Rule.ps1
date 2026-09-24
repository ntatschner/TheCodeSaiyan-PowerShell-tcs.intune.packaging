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
                $fileParams += $MultiSetParameters[0]
                $fileParams += $MultiSetParameters[1]
                foreach ($p in $fileParams) {
                    $param = $(New-DynamicParameter @p)
                    $paramDictionary.Add($param.Name, $param.Parameter)
                }
            }
            'Registry' {
                $registryParams = @(
                    @{Name = "Path"; ParameterType = [string]; Mandatory = $true; HelpMessage = "The registry key path, for example HKEY_LOCAL_MACHINE\Software." }
                    @{Name = "KeyName"; ParameterType = [string]; HelpMessage = "The registry key name, appended to Path." }
                    @{Name = "Check32BitOn64BitSystem"; ParameterType = [switch]; HelpMessage = "Search the 32-bit registry on 64-bit systems." }
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
    begin {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        $TelemetryFailed = $false
    }
    process {
        try {
            # Builds the rule types documented at
            # https://learn.microsoft.com/graph/api/resources/intune-apps-win32lobapprule
            # Dynamic parameters are not created as variables, so read them from PSBoundParameters
            $Bound = $PSBoundParameters
            $Operator = $(if ($Bound.ContainsKey('Operator')) { $Bound['Operator'] } else { 'notConfigured' })
            $Rule = [ordered]@{}
            switch ($RuleType) {
                'FileOrFolder' {
                    $Rule['@odata.type'] = '#microsoft.graph.win32LobAppFileSystemRule'
                    $Rule['ruleType'] = $RuleParentType
                    $Rule['path'] = $Bound['Path']
                    $Rule['fileOrFolderName'] = $Bound['FileOrFolderName']
                    $Rule['check32BitOn64System'] = [bool]$Bound['Check32BitOn64BitSystem']
                    $Rule['operationType'] = $Bound['OperationType']
                    $Rule['operator'] = $Operator
                    if ($Bound.ContainsKey('ComparisonValue')) {
                        $Rule['comparisonValue'] = $Bound['ComparisonValue']
                    }
                }
                'Registry' {
                    $KeyPath = [string]$Bound['Path']
                    if ($Bound['KeyName']) {
                        $KeyPath = $KeyPath.TrimEnd('\') + '\' + $Bound['KeyName']
                    }
                    $Rule['@odata.type'] = '#microsoft.graph.win32LobAppRegistryRule'
                    $Rule['ruleType'] = $RuleParentType
                    $Rule['check32BitOn64System'] = [bool]$Bound['Check32BitOn64BitSystem']
                    $Rule['keyPath'] = $KeyPath
                    $Rule['valueName'] = [string]$Bound['ValueName']
                    switch ($Operator) {
                        'exists' {
                            $Rule['operationType'] = 'exists'
                            $Rule['operator'] = 'notConfigured'
                        }
                        'notExists' {
                            $Rule['operationType'] = 'doesNotExist'
                            $Rule['operator'] = 'notConfigured'
                        }
                        'notConfigured' {
                            # Without an operator the rule checks that the key or value exists
                            $Rule['operationType'] = 'exists'
                            $Rule['operator'] = 'notConfigured'
                        }
                        default {
                            if (-not $Bound.ContainsKey('DataType')) {
                                throw "A registry comparison ($Operator) needs -DataType (string, integer or version)."
                            }
                            $Rule['operationType'] = $Bound['DataType']
                            $Rule['operator'] = $Operator
                            $Rule['comparisonValue'] = [string]$Bound['Value']
                        }
                    }
                }
                'Script' {
                    $ScriptPath = $Bound['ScriptPath']
                    try {
                        $ScriptContent = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
                    }
                    catch {
                        throw "Failed to read script content from $($ScriptPath): $($_.Exception.Message)"
                    }
                    $Rule['@odata.type'] = '#microsoft.graph.win32LobAppPowerShellScriptRule'
                    $Rule['ruleType'] = $RuleParentType
                    $Rule['enforceSignatureCheck'] = [bool]$Bound['EnforceSignatureCheck']
                    $Rule['runAs32Bit'] = [bool]$Bound['RunAs32Bit']
                    $Rule['scriptContent'] = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ScriptContent))
                    if ($RuleParentType -eq 'detection') {
                        # Detection scripts must not set displayName, runAsAccount or a comparison
                        $Rule['operationType'] = 'notConfigured'
                        $Rule['operator'] = 'notConfigured'
                    }
                    else {
                        $Rule['displayName'] = $(if ($Bound['DisplayName']) { $Bound['DisplayName'] } else { Split-Path -Path $ScriptPath -Leaf })
                        $Rule['runAsAccount'] = $Bound['RunAsAccount']
                        $Rule['operationType'] = $(if ($Bound.ContainsKey('OperationType')) { $Bound['OperationType'] } else { 'notConfigured' })
                        $Rule['operator'] = $Operator
                        if ($Bound.ContainsKey('ComparisonValue')) {
                            $Rule['comparisonValue'] = $Bound['ComparisonValue']
                        }
                    }
                }
                'MSI' {
                    if ($RuleParentType -ne 'detection') {
                        throw 'MSI (product code) rules can only be used as detection rules.'
                    }
                    $ProductCode = $Bound['ProductCode']
                    $ProductVersion = $Bound['ProductVersion']
                    $VersionOperator = $(if ($Bound.ContainsKey('ProductVersionOperator')) { $Bound['ProductVersionOperator'] } else { 'notConfigured' })
                    if ($Bound['AutoDetect'] -eq $true) {
                        $MSIInfo = Get-MSIProperty -Path $Bound['MSIPath'] -ErrorAction Stop
                        $ProductCode = $MSIInfo.ProductCode
                        $ProductVersion = $MSIInfo.ProductVersion
                        $VersionOperator = 'equal'
                    }
                    if ([string]::IsNullOrEmpty($ProductCode)) {
                        throw 'An MSI rule needs -ProductCode or -AutoDetect $true.'
                    }
                    $Rule['@odata.type'] = '#microsoft.graph.win32LobAppProductCodeRule'
                    $Rule['ruleType'] = $RuleParentType
                    $Rule['productCode'] = $ProductCode
                    $Rule['productVersionOperator'] = $VersionOperator
                    $Rule['productVersion'] = $ProductVersion
                }
            }
            # Return a plain hashtable (the documented output type) with the keys in a stable order
            $Result = @{}
            foreach ($Key in $Rule.Keys) {
                $Result[$Key] = $Rule[$Key]
            }
            $Result
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            throw
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
