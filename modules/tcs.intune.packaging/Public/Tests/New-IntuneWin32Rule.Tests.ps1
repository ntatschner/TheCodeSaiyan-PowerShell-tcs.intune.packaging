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
        $rule = New-IntuneWin32Rule -RuleParentType detection -RuleType Registry -Path $TestDrive -KeyName 'MyApp' -Verbose 4>$null
        $rule.Keys | Should -Not -Contain 'verbose'
        $rule['keyName'] | Should -Be 'MyApp'
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
