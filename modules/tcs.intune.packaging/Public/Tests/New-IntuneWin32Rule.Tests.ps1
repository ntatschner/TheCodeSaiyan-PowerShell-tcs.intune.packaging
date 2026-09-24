BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.intune.packaging.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.intune.packaging -Force -ErrorAction SilentlyContinue
}
Describe 'New-IntuneWin32Rule' {
    It 'Is exported under its file name' {
        Get-Command -Name New-IntuneWin32Rule -Module tcs.intune.packaging | Should -Not -BeNullOrEmpty
    }

    It 'Creates a file system detection rule with Graph property names' {
        # Test-Path -IsValid only accepts paths of the current platform, so use a TestDrive path
        $folder = Join-Path -Path $TestDrive -ChildPath 'MyApp'
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType FileOrFolder -Path $folder -FileOrFolderName 'MyApp.exe' -OperationType exists
        $rule['@odata.type'] | Should -Be '#microsoft.graph.win32LobAppFileSystemRule'
        $rule['ruleType'] | Should -Be 'detection'
        $rule['path'] | Should -Be $folder
        $rule['fileOrFolderName'] | Should -Be 'MyApp.exe'
        $rule['operationType'] | Should -Be 'exists'
        $rule['check32BitOn64System'] | Should -BeFalse
        $rule.ContainsKey('verbose') | Should -BeFalse
    }

    It 'Maps Check32BitOn64BitSystem to check32BitOn64System' {
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType FileOrFolder -Path $TestDrive -FileOrFolderName 'a.exe' -OperationType exists -Check32BitOn64BitSystem
        $rule['check32BitOn64System'] | Should -BeTrue
        $rule.Keys | Should -Not -Contain 'check32BitOn64BitSystem'
    }

    It 'Leaves common parameters out of the rule' {
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType Registry -Path 'HKEY_LOCAL_MACHINE\Software' -KeyName 'MyApp' -Verbose 4>$null
        $rule.Keys | Should -Not -Contain 'verbose'
    }

    It 'Creates a registry <Case> rule with Graph property names' -ForEach @(
        @{ Case = 'exists'; Extra = @{ Operator = 'exists' }; OperationType = 'exists'; Operator = 'notConfigured'; Comparison = $null }
        @{ Case = 'does not exist'; Extra = @{ Operator = 'notExists' }; OperationType = 'doesNotExist'; Operator = 'notConfigured'; Comparison = $null }
        @{ Case = 'version comparison'; Extra = @{ Operator = 'greaterThanOrEqual'; DataType = 'version'; Value = '1.2' }; OperationType = 'version'; Operator = 'greaterThanOrEqual'; Comparison = '1.2' }
    ) {
        $rule = New-IntuneWin32Rule -RuleParentType requirement -RuleType Registry -Path 'HKEY_LOCAL_MACHINE\Software\' -KeyName 'MyApp' -ValueName 'Version' @Extra
        $rule['@odata.type'] | Should -Be '#microsoft.graph.win32LobAppRegistryRule'
        $rule['ruleType'] | Should -Be 'requirement'
        $rule['keyPath'] | Should -Be 'HKEY_LOCAL_MACHINE\Software\MyApp'
        $rule['valueName'] | Should -Be 'Version'
        $rule['check32BitOn64System'] | Should -BeFalse
        $rule['operationType'] | Should -Be $OperationType
        $rule['operator'] | Should -Be $Operator
        $rule['comparisonValue'] | Should -Be $Comparison
        @($rule.Keys | Where-Object { $_ -in 'path', 'keyName', 'dataType', 'value' }) | Should -BeNullOrEmpty
    }

    It 'Requires a data type for a registry comparison' {
        { New-IntuneWin32Rule -RuleParentType detection -RuleType Registry -Path 'HKLM\Software' -Operator equal -Value 1 } | Should -Throw '*DataType*'
    }

    It 'Adds the comparison to a file version rule' {
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType FileOrFolder -Path $TestDrive -FileOrFolderName 'app.exe' -OperationType version -Operator greaterThanOrEqual -ComparisonValue '2.0'
        $rule['operator'] | Should -Be 'greaterThanOrEqual'
        $rule['comparisonValue'] | Should -Be '2.0'
    }

    It 'Leaves displayName and runAsAccount out of script detection rules and sets them for requirement rules' {
        $script = Join-Path -Path $TestDrive -ChildPath 'req.ps1'
        Set-Content -Path $script -Value 'Write-Output 1'
        $detection = New-IntuneWin32Rule -RuleParentType detection -RuleType Script -ScriptPath $script
        $detection.Keys | Should -Not -Contain 'displayName'
        $detection.Keys | Should -Not -Contain 'runAsAccount'
        $requirement = New-IntuneWin32Rule -RuleParentType requirement -RuleType Script -ScriptPath $script -RunAsAccount user -OperationType integer -Operator equal -ComparisonValue '1'
        $requirement['runAsAccount'] | Should -Be 'user'
        $requirement['displayName'] | Should -Be 'req.ps1'
        $requirement['operationType'] | Should -Be 'integer'
        $requirement['comparisonValue'] | Should -Be '1'
    }

    It 'Only allows MSI rules for detection' {
        $msi = Join-Path -Path $TestDrive -ChildPath 'app.msi'
        Set-Content -Path $msi -Value 'x'
        { New-IntuneWin32Rule -RuleParentType requirement -RuleType MSI -MSIPath $msi -ProductCode '{A}' } | Should -Throw '*detection*'
    }

    It 'Embeds the script content as Base64' {
        $script = Join-Path -Path $TestDrive -ChildPath 'detect.ps1'
        Set-Content -Path $script -Value 'Write-Output "found"' -NoNewline
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType Script -ScriptPath $script
        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($rule['scriptContent'])) | Should -Be 'Write-Output "found"'
        $rule['@odata.type'] | Should -Be '#microsoft.graph.win32LobAppPowerShellScriptRule'
        $rule['operationType'] | Should -Be 'notConfigured'
        $rule.Keys | Should -Not -Contain 'scriptPath'
    }

    It 'Reads the product code from the MSI when AutoDetect is used' {
        Mock -ModuleName tcs.intune.packaging Get-MSIProperty { [PSCustomObject]@{ ProductCode = '{ABC}'; ProductVersion = '1.2.3' } }
        $msi = Join-Path -Path $TestDrive -ChildPath 'app.msi'
        Set-Content -Path $msi -Value 'x'
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType MSI -MSIPath $msi -AutoDetect $true
        $rule['productCode'] | Should -Be '{ABC}'
        $rule['productVersion'] | Should -Be '1.2.3'
        $rule['productVersionOperator'] | Should -Be 'equal'
        $rule.Keys | Should -Not -Contain 'msiPath'
    }
}

Describe 'New-IntuneWin32Rule telemetry' {
    BeforeEach {
        Mock -ModuleName tcs.intune.packaging Invoke-TelemetryCollection { }
    }

    It 'Reports Start and a successful End' {
        $null = New-IntuneWin32Rule -RuleParentType detection -RuleType Registry -Path 'HKEY_LOCAL_MACHINE\Software\MyApp' -Operator exists
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'Start' -and $CommandName -eq 'New-IntuneWin32Rule' }
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
    }

    It 'Reports a failed End once and still throws' {
        { New-IntuneWin32Rule -RuleParentType detection -RuleType Registry -Path 'HKEY_LOCAL_MACHINE\Software\MyApp' -ValueName 'Version' -Operator equal -Value '1.0' } | Should -Throw '*DataType*'
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'Start' }
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 1 -Exactly -ParameterFilter { $Stage -eq 'End' -and $Failed -eq $true }
        Should -Invoke -ModuleName tcs.intune.packaging Invoke-TelemetryCollection -Times 0 -Exactly -ParameterFilter { $Stage -eq 'End' -and -not $Failed }
    }
}
