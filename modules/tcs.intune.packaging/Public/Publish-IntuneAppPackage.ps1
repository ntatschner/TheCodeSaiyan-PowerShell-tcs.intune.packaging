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
            -Force it uploads the package as a new content version of the existing app.

        The detection and requirement rules come from -Rules or, when omitted, from
        DetectionRuleConfig and RequirementRuleConfig in the JSON file. They must be rules created with
        New-IntuneWin32Rule (hashtables with an '@odata.type').

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

    .PARAMETER IntuneAppJSONPath
        The path to the application configuration JSON file created by New-IntuneApplication.

    .PARAMETER IntuneWinPath
        The path to the .intunewin package file.

    .PARAMETER Force
        Upload the package as a new content version when an app with the same display name exists.

    .PARAMETER NoTenantDetails
        Do not show the tenant connection details.

    .PARAMETER Rules
        Detection and requirement rules created with New-IntuneWin32Rule. Overrides the rules in the JSON file.

    .PARAMETER PollIntervalSeconds
        How often to check the upload and commit state. Default is 5 seconds.

    .PARAMETER TimeoutSeconds
        How long to wait for each upload or commit state. Default is 600 seconds.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        The Win32 app (id, displayName and committedContentVersion).

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.0.json" -IntuneWinPath "C:\Packages\setup.intunewin"

        Creates the MyApp Win32 app in Intune and uploads setup.intunewin.

    .EXAMPLE
        Publish-IntuneAppPackage -IntuneAppJSONPath "C:\Packages\MyApp.1.1.json" -IntuneWinPath "C:\Packages\setup.intunewin" -Force -NoTenantDetails

        Uploads setup.intunewin as a new content version of the existing MyApp app.

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
        [int]$TimeoutSeconds = 600
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
            $AppParameters = (Get-Content -Path $IntuneAppJSONPath -Raw -ErrorAction Stop | ConvertFrom-Json).ApplicationParameters
            if (-not $AppParameters -or [string]::IsNullOrEmpty($AppParameters.ApplicationName)) {
                throw "'$IntuneAppJSONPath' does not contain ApplicationParameters.ApplicationName."
            }
            $DisplayName = [string]$AppParameters.ApplicationName

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
                if (-not $PSCmdlet.ShouldProcess("$DisplayName ($($Existing.id))", "Upload '$IntuneWinPath' as a new content version")) {
                    Invoke-TelemetryCollection @TelemetryArgs -Stage End
                    return
                }
                $ContentVersion = Publish-IntuneWin32AppContent -AppId $Existing.id -IntuneWinPath $IntuneWinPath -PollIntervalSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds -ErrorAction Stop
                [PSCustomObject]@{
                    id                      = $Existing.id
                    displayName             = $Existing.displayName
                    committedContentVersion = $ContentVersion
                }
                Invoke-TelemetryCollection @TelemetryArgs -Stage End
                return
            }

            # Convert the rules in the JSON file (PSCustomObjects) to hashtables
            if (-not $PSBoundParameters.ContainsKey('Rules')) {
                $Rules = foreach ($Config in @($AppParameters.DetectionRuleConfig, $AppParameters.RequirementRuleConfig)) {
                    foreach ($Rule in @($Config | Where-Object { $_ })) {
                        $Hashtable = @{}
                        foreach ($Property in $Rule.PSObject.Properties) {
                            $Hashtable[$Property.Name] = $Property.Value
                        }
                        if (-not $Hashtable.ContainsKey('@odata.type')) {
                            throw "The rule configuration in '$IntuneAppJSONPath' is not a Win32 app rule. Create the rules with New-IntuneWin32Rule, or pass them with -Rules."
                        }
                        $Hashtable
                    }
                }
            }

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

            New-IntuneWin32Application @Splat
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
