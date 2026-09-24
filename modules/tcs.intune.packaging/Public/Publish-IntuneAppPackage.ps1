function Publish-IntuneAppPackage {
    <#
    .SYNOPSIS
        Publishes an Intune Win32 application package (.intunewin and its JSON configuration) to Microsoft Intune.

    .DESCRIPTION
        The Publish-IntuneAppPackage function reads the application configuration JSON created by
        New-IntuneApplication and publishes the .intunewin package with Microsoft Graph:

          - When no app with the same display name exists, it creates the Win32 app and uploads the
            package (see New-IntuneWin32Application).
          - When a Win32 app with the same display name exists, it stops unless -Force is used; with
            -Force it uploads the package as a new content version of the existing app and then
            updates the app's properties from the JSON file (PATCH): display name, description,
            publisher, developer, owner, notes (with "Version: <version>"), featured, install and
            uninstall command lines, install experience, logo, rules, and the setup file and file name
            of the new package.

        Then the app is assigned when an assignment type is set, either with -AssignmentType or by
        AssignmentType in the JSON file (New-IntuneApplication writes it): to a group (User-Group or
        Device-Group, by group ID or display name), all users or all devices, with the intent
        required (default), available or uninstall, and optionally an assignment filter
        (FilterRuleType Include or Exclude, FilterRule the filter name or ID). Existing assignments are
        kept; one to the same target is replaced. Use -NoAssignment to skip this. Assignments use the
        Graph beta endpoint because assignment filters are only there.

        The detection and requirement rules come from -Rules or, when omitted, from
        DetectionRuleConfig and RequirementRuleConfig in the JSON file. They must be rules created with
        New-IntuneWin32Rule (hashtables with an '@odata.type').

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All (and Group.Read.All to assign to a
        group by display name).

    .PARAMETER IntuneAppJSONPath
        The path to the application configuration JSON file created by New-IntuneApplication.

    .PARAMETER IntuneWinPath
        The path to the .intunewin package file.

    .PARAMETER Force
        Upload the package as a new content version when an app with the same display name exists, and
        update the app's properties from the JSON file.

    .PARAMETER NoTenantDetails
        Do not show the tenant connection details.

    .PARAMETER Rules
        Detection and requirement rules created with New-IntuneWin32Rule. Overrides the rules in the JSON file.

    .PARAMETER PollIntervalSeconds
        How often to check the upload and commit state. Default is 5 seconds.

    .PARAMETER TimeoutSeconds
        How long to wait for each upload or commit state. Default is 600 seconds.

    .PARAMETER AssignmentType
        How the app is assigned: User-Group, Device-Group, All-Users or All-Devices. Overrides
        AssignmentType in the JSON file.

    .PARAMETER AssignmentGroup
        The group ID or display name for User-Group and Device-Group. Overrides the JSON file.

    .PARAMETER AssignmentIntent
        The assignment intent: required, available or uninstall. Overrides the JSON file; default required.

    .PARAMETER FilterRuleType
        Include or Exclude, for an assignment filter. Overrides the JSON file.

    .PARAMETER FilterRule
        The name or ID of an existing Intune assignment filter. Overrides the JSON file.

    .PARAMETER NoAssignment
        Do not assign the app, even when the JSON file has an assignment type.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        The Win32 app (id, displayName and committedContentVersion), with Assignment (the assignment
        that was sent) when the app was assigned.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.0.json" -IntuneWinPath "C:\Packages\setup.intunewin"

        Creates the MyApp Win32 app in Intune and uploads setup.intunewin.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.1.json" -IntuneWinPath "C:\Packages\setup.intunewin" -Force -NoTenantDetails

        Uploads setup.intunewin as a new content version of the existing MyApp app and updates its
        properties from the JSON file.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.0.json" -IntuneWinPath "C:\Packages\setup.intunewin" -AssignmentType User-Group -AssignmentGroup 'Intune-AG-MyApp-Available' -AssignmentIntent available

        Creates the app and makes it available to the members of the Intune-AG-MyApp-Available group.

    .NOTES
        Requires connection to Microsoft Graph using Connect-MgGraph before running this function.

    .LINK
        New-IntuneWin32Application
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IntuneAppJSONPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IntuneWinPath,

        [switch]$Force,

        [switch]$NoTenantDetails,

        [hashtable[]]$Rules,

        [ValidateRange(0, 300)]
        [int]$PollIntervalSeconds = 5,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 600,

        [ValidateSet('User-Group', 'Device-Group', 'All-Users', 'All-Devices')]
        [string]$AssignmentType,

        [string]$AssignmentGroup,

        [ValidateSet('required', 'available', 'uninstall')]
        [string]$AssignmentIntent,

        [ValidateSet('Include', 'Exclude')]
        [string]$FilterRuleType,

        [string]$FilterRule,

        [switch]$NoAssignment
    )
    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        try {
            $GraphContext = Assert-MgGraphConnection
            $AppJson = Read-IntuneAppJson -Path $IntuneAppJSONPath -IgnoreRules:$PSBoundParameters.ContainsKey('Rules')
            $AppParameters = $AppJson.AppParameters
            $DisplayName = $AppJson.DisplayName
            if (-not $PSBoundParameters.ContainsKey('Rules')) {
                $Rules = $AppJson.Rules
            }

            # Assignment settings: parameters win over the JSON file. Checked before anything is created.
            $Assignment = $null
            if (-not $NoAssignment) {
                $AssignmentSettings = @{}
                foreach ($Pair in @(@('AssignmentType', 'AssignmentType'), @('AssignmentGroup', 'AssignmentGroup'), @('AssignmentIntent', 'Intent'),
                        @('FilterRuleType', 'FilterRuleType'), @('FilterRule', 'FilterRule'))) {
                    $Value = $(if ($PSBoundParameters.ContainsKey($Pair[0])) { $PSBoundParameters[$Pair[0]] } else { $AppParameters.($Pair[0]) })
                    if (-not [string]::IsNullOrWhiteSpace([string]$Value)) {
                        $AssignmentSettings[$Pair[1]] = [string]$Value
                    }
                }
                if ($AssignmentSettings.ContainsKey('AssignmentType')) {
                    Test-IntuneAppAssignmentSetting @AssignmentSettings
                }
                else {
                    $AssignmentSettings = $null
                }
            }

            if (-not $NoTenantDetails) {
                Write-Information -MessageData ("You're connected to Microsoft Graph as:`n`tUserName: $($GraphContext.Account)`n`t" +
                    "Context scope: $($GraphContext.ContextScope)`n`tTenantId: $($GraphContext.TenantId)") -InformationAction Continue
            }

            # Check if a Win32 app with the same display name already exists
            $Filter = [System.Uri]::EscapeDataString("displayName eq '$($DisplayName.Replace("'", "''"))'")
            $Response = Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceAppManagement/mobileApps?`$filter=$Filter" -OutputType PSObject -ErrorAction Stop
            $Existing = @($Response.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.win32LobApp' }) | Select-Object -First 1

            if ($Existing) {
                if (-not $Force) {
                    throw "The application '$DisplayName' already exists in Intune ($($Existing.id)). Use -Force to upload the package as a new content version."
                }
                if (-not $PSCmdlet.ShouldProcess("$DisplayName ($($Existing.id))", "Upload '$IntuneWinPath' as a new content version and update the app properties")) {
                    Invoke-TelemetryCollection @TelemetryArgs -Stage End
                    return
                }
                $ContentVersion = Publish-IntuneWin32AppContent -AppId $Existing.id -IntuneWinPath $IntuneWinPath -PollIntervalSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds -ErrorAction Stop

                # The new content is committed: update the properties to match the JSON file and package
                $Package = Read-IntuneWinPackage -Path $IntuneWinPath -ErrorAction Stop
                $Patch = ConvertTo-IntuneWin32AppPatch -AppParameters $AppParameters -Rules $Rules
                $Patch['setupFilePath'] = $Package.SetupFile
                $Patch['fileName'] = Split-Path -Path $IntuneWinPath -Leaf
                Write-Verbose "Updating the properties of app $($Existing.id)."
                $null = Invoke-MgGraphRequest -Method PATCH -Uri "v1.0/deviceAppManagement/mobileApps/$($Existing.id)" -Body ($Patch | ConvertTo-Json -Depth 10 -Compress) -ContentType 'application/json' -ErrorAction Stop

                $App = [PSCustomObject]@{
                    id                      = $Existing.id
                    displayName             = $(if ($Patch.Contains('displayName')) { $Patch['displayName'] } else { $Existing.displayName })
                    committedContentVersion = $ContentVersion
                }
            }
            else {
                $Splat = @{
                    Name                 = $DisplayName
                    Description          = [string]$AppParameters.Description
                    Publisher            = [string]$AppParameters.Publisher
                    InstallCommandLine   = [string]$AppParameters.InstallCommand
                    UninstallCommandLine = [string]$AppParameters.UninstallCommand
                    Rules                = @($Rules)
                    IntuneWinFilePath    = $IntuneWinPath
                    PollIntervalSeconds  = $PollIntervalSeconds
                    TimeoutSeconds       = $TimeoutSeconds
                    ErrorAction          = 'Stop'
                }
                foreach ($Pair in @(
                        @('Developer', 'Developer'), @('Owner', 'Owner'), @('Notes', 'Notes'), @('IsFeatured', 'IsFeatured'),
                        @('InstallFor', 'InstallExperienceRunAsAccount'), @('RestartBehavior', 'InstallExperienceDeviceRestartBehavior'), @('LogoPath', 'IconFilePath'))) {
                    $Value = $AppParameters.($Pair[0])
                    if ($null -ne $Value -and "$Value" -ne '') {
                        if ($Pair[1] -eq 'InstallExperienceRunAsAccount') {
                            $Value = ([string]$Value).ToLowerInvariant()
                        }
                        $Splat[$Pair[1]] = $Value
                    }
                }
                $ParsedVersion = $null
                if ([version]::TryParse([string]$AppParameters.Version, [ref]$ParsedVersion)) {
                    $Splat['Version'] = $ParsedVersion
                }
                $App = New-IntuneWin32Application @Splat
            }

            if ($App -and $AssignmentSettings) {
                $Target = $(if ($AssignmentSettings['AssignmentGroup']) { "$($AssignmentSettings['AssignmentType']) '$($AssignmentSettings['AssignmentGroup'])'" } else { $AssignmentSettings['AssignmentType'] })
                if ($PSCmdlet.ShouldProcess("$DisplayName ($($App.id))", "Assign to $Target")) {
                    $Assignment = Add-IntuneWin32AppAssignment -AppId $App.id @AssignmentSettings -ErrorAction Stop
                    $App | Add-Member -NotePropertyName Assignment -NotePropertyValue $Assignment -Force
                }
            }
            $App
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
