function Set-IntuneWin32App {
    <#
    .SYNOPSIS
        Updates the properties and rules of a Win32 app in Microsoft Intune.

    .DESCRIPTION
        The Set-IntuneWin32App function updates an existing Win32 app with Microsoft Graph v1.0
        (PATCH /deviceAppManagement/mobileApps/{id}). Only the properties you give are changed.

        With JsonPath the properties and rules come from the application JSON written by
        New-IntuneApplication (display name, description, publisher, developer, owner, notes, version,
        featured, install and uninstall command lines, install experience, logo and the detection and
        requirement rules), as Publish-IntuneAppPackage -Force applies them.

        Graph v1.0 has no version property for Win32 apps: Version is added to the notes as
        "Version: <version>" (the current notes are read when Notes is not given). Rules replace all
        rules of the app and must contain a detection rule. The package content is not changed; use
        Publish-IntuneAppPackage -Force to upload a new package.

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

    .PARAMETER Id
        The ID of the Win32 app. Accepts pipeline input by property name (id), for example from
        Get-IntuneWin32App.

    .PARAMETER JsonPath
        The application JSON file created by New-IntuneApplication.

    .PARAMETER Name
        The display name.

    .PARAMETER Description
        The description.

    .PARAMETER Publisher
        The publisher.

    .PARAMETER Owner
        The owner.

    .PARAMETER Developer
        The developer.

    .PARAMETER Notes
        The notes.

    .PARAMETER Version
        The version, added to the notes as "Version: <version>".

    .PARAMETER PrivacyInformationUrl
        URL of the privacy statement.

    .PARAMETER InformationUrl
        URL with more information about the app.

    .PARAMETER IsFeatured
        Whether the app is featured in the Company Portal.

    .PARAMETER InstallCommandLine
        The command line that installs the app.

    .PARAMETER UninstallCommandLine
        The command line that uninstalls the app.

    .PARAMETER InstallExperienceRunAsAccount
        The context the app is installed in: system or user. Use with InstallExperienceDeviceRestartBehavior
        or on its own (the restart behaviour is then basedOnReturnCode).

    .PARAMETER InstallExperienceDeviceRestartBehavior
        The restart behaviour: basedOnReturnCode, allow, suppress or force.

    .PARAMETER Rules
        Detection and requirement rules created with New-IntuneWin32Rule. They replace all rules of the app.

    .PARAMETER PassThru
        Returns the updated app.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        The updated win32LobApp with -PassThru; otherwise nothing.

    .EXAMPLE
        Set-IntuneWin32App -Id $app.id -InstallCommandLine 'setup.exe /S /norestart' -Version '2.0.1'

        Changes the install command line and records version 2.0.1 in the notes.

    .EXAMPLE
        Get-IntuneWin32App -Name 'MyApp' | Set-IntuneWin32App -JsonPath C:\Packages\MyApp.2.0.json -PassThru

        Updates MyApp from the JSON file written by New-IntuneApplication.

    .LINK
        https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-update
    #>
    [CmdletBinding(DefaultParameterSetName = 'Parameters', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory, ParameterSetName = 'Json')]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$JsonPath,

        [Parameter(ParameterSetName = 'Parameters')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Publisher,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Owner,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Developer,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Notes,

        [Parameter(ParameterSetName = 'Parameters')]
        [version]$Version,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$PrivacyInformationUrl,

        [Parameter(ParameterSetName = 'Parameters')]
        [string]$InformationUrl,

        [Parameter(ParameterSetName = 'Parameters')]
        [bool]$IsFeatured,

        [Parameter(ParameterSetName = 'Parameters')]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [Parameter(ParameterSetName = 'Parameters')]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [Parameter(ParameterSetName = 'Parameters')]
        [ValidateSet('system', 'user')]
        [string]$InstallExperienceRunAsAccount,

        [Parameter(ParameterSetName = 'Parameters')]
        [ValidateSet('allow', 'basedOnReturnCode', 'suppress', 'force')]
        [string]$InstallExperienceDeviceRestartBehavior,

        [Parameter(ParameterSetName = 'Parameters')]
        [hashtable[]]$Rules,

        [switch]$PassThru
    )
    begin {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        $TelemetryFailed = $false
        try {
            $null = Assert-MgGraphConnection
        }
        catch {
            $TelemetryFailed = $true
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        try {
            $AppUri = "v1.0/deviceAppManagement/mobileApps/$([System.Uri]::EscapeDataString($Id))"
            if ($PSCmdlet.ParameterSetName -eq 'Json') {
                $AppJson = Read-IntuneAppJson -Path $JsonPath
                $Body = ConvertTo-IntuneWin32AppPatch -AppParameters $AppJson.AppParameters -Rules $AppJson.Rules
            }
            else {
                $Settings = @{}
                $Map = [ordered]@{
                    Name                 = 'ApplicationName'
                    Description          = 'Description'
                    Publisher            = 'Publisher'
                    Owner                = 'Owner'
                    Developer            = 'Developer'
                    Notes                = 'Notes'
                    IsFeatured           = 'IsFeatured'
                    InstallCommandLine   = 'InstallCommand'
                    UninstallCommandLine = 'UninstallCommand'
                }
                foreach ($Parameter in $Map.Keys) {
                    if ($PSBoundParameters.ContainsKey($Parameter)) {
                        $Settings[$Map[$Parameter]] = $PSBoundParameters[$Parameter]
                    }
                }
                if ($Version) {
                    $Settings['Version'] = $Version.ToString()
                    if (-not $PSBoundParameters.ContainsKey('Notes')) {
                        # Append the version to the current notes
                        $Current = Invoke-MgGraphRequest -Method GET -Uri $AppUri -OutputType PSObject -ErrorAction Stop
                        $Settings['Notes'] = [string]$Current.notes
                    }
                }
                if ($InstallExperienceRunAsAccount) {
                    $Settings['InstallFor'] = $InstallExperienceRunAsAccount
                }
                if ($InstallExperienceDeviceRestartBehavior) {
                    $Settings['RestartBehavior'] = $InstallExperienceDeviceRestartBehavior
                }
                $Body = ConvertTo-IntuneWin32AppPatch -AppParameters $Settings -Rules $Rules
                if ($PSBoundParameters.ContainsKey('PrivacyInformationUrl')) {
                    $Body['privacyInformationUrl'] = $PrivacyInformationUrl
                }
                if ($PSBoundParameters.ContainsKey('InformationUrl')) {
                    $Body['informationUrl'] = $InformationUrl
                }
            }
            if ($Body.Contains('rules') -and -not @($Body['rules'] | Where-Object { $_.ruleType -eq 'detection' })) {
                throw 'Rules must contain at least one detection rule. Create one with New-IntuneWin32Rule -RuleParentType detection.'
            }
            if ($Body.Count -le 1) {
                throw 'Nothing to update: give at least one property to change, or -JsonPath.'
            }

            $Properties = @($Body.Keys | Where-Object { $_ -ne '@odata.type' }) -join ', '
            if ($PSCmdlet.ShouldProcess($Id, "Update Intune Win32 app properties: $Properties")) {
                $null = Invoke-MgGraphRequest -Method PATCH -Uri $AppUri -Body ($Body | ConvertTo-Json -Depth 10 -Compress) -ContentType 'application/json' -ErrorAction Stop
                if ($PassThru) {
                    Invoke-MgGraphRequest -Method GET -Uri $AppUri -OutputType PSObject -ErrorAction Stop
                }
            }
        }
        catch {
            if (-not $TelemetryFailed) {
                $TelemetryFailed = $true
                Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        if (-not $TelemetryFailed) {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
    }
}
