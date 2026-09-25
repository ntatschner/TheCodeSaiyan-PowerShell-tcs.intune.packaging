function New-IntuneWin32Application {
    <#
    .SYNOPSIS
        Creates a Win32 application in Microsoft Intune and uploads its .intunewin package.

    .DESCRIPTION
        The New-IntuneWin32Application function creates a win32LobApp in Microsoft Intune with
        Microsoft Graph (POST /deviceAppManagement/mobileApps), uploads the encrypted content of the
        package (.intunewin file) to Azure Storage, commits it and sets the app's committed content version.
        The app is returned when the upload is complete.

        With ExistingPackage the properties of an existing Win32 app are copied (display name,
        description, publisher, owner, developer, notes, URLs, command lines, rules, return codes,
        install experience and requirements); parameters you specify win over the copied values.
        Assignments and supersedence are not copied.

        Requires the Microsoft.Graph.Authentication module and a connection made with
        Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All.

    .PARAMETER Name
        The display name of the application.

    .PARAMETER Description
        A description of the application.

    .PARAMETER Version
        The application version. Graph v1.0 has no version property for Win32 apps, so the version is
        added to the notes as "Version: <version>" unless the notes already contain it.

    .PARAMETER Publisher
        The publisher of the application.

    .PARAMETER Owner
        The owner of the application.

    .PARAMETER Developer
        The developer of the application.

    .PARAMETER Notes
        Notes for the application.

    .PARAMETER PrivacyInformationUrl
        URL of the privacy statement.

    .PARAMETER InformationUrl
        URL with more information about the application.

    .PARAMETER IsFeatured
        Whether the application is featured in the Company Portal.

    .PARAMETER ApplicableArchitectures
        The architectures the app applies to: x86, x64, arm or neutral. Default is x64.

    .PARAMETER MinimumFreeDiskSpaceInMB
        The minimum free disk space, in MB, required to install the app.

    .PARAMETER MinimumMemoryInMB
        The minimum physical memory, in MB, required to install the app.

    .PARAMETER MinimumNumberOfProcessors
        The minimum number of processors required to install the app.

    .PARAMETER MinimumCpuSpeedInMHz
        The minimum CPU speed, in MHz, required to install the app.

    .PARAMETER InstallExperienceRunAsAccount
        The context the app is installed in: system or user. Default is system.

    .PARAMETER InstallExperienceDeviceRestartBehavior
        The restart behaviour: basedOnReturnCode, allow, suppress or force. Default is basedOnReturnCode.

    .PARAMETER MinimumSupportedWindowsRelease
        The minimum supported Windows release, for example 'Windows11_23H2'. Not sent when omitted.

    .PARAMETER InstallCommandLine
        The command line that installs the app, for example 'msiexec /i "setup.msi" /qn'.

    .PARAMETER UninstallCommandLine
        The command line that uninstalls the app.

    .PARAMETER Rules
        Detection and requirement rules created with New-IntuneWin32Rule. At least one detection rule
        is required for a new app.

    .PARAMETER ReturnCodes
        Return codes as hashtables with returnCode and type (success, failed, softReboot, hardReboot,
        retry). Default: 0 and 1707 success, 3010 softReboot, 1641 hardReboot, 1618 retry.

    .PARAMETER IconFilePath
        Path to a PNG or JPG icon for the app.

    .PARAMETER IntuneWinFilePath
        The path to the .intunewin package file.

    .PARAMETER ExistingPackage
        The existing application to clone, as "<DisplayName> | <Id>" or just the app ID. Tab completion
        lists the Win32 apps in the connected tenant.

    .PARAMETER PollIntervalSeconds
        How often to check the upload and commit state. Default is 5 seconds.

    .PARAMETER TimeoutSeconds
        How long to wait for each upload or commit state. Default is 600 seconds.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        The created win32LobApp as returned by Microsoft Graph, with committedContentVersion set.

    .EXAMPLE
        $detection = New-IntuneWin32Rule -RuleParentType detection -RuleType MSI -MSIPath .\setup.msi -AutoDetect $true
        New-IntuneWin32Application -Name "MyApp" -Description "My Application" -Publisher "Contoso" -Owner "IT" -Developer "Dev Team" -InstallCommandLine 'msiexec /i "setup.msi" /qn' -UninstallCommandLine 'msiexec /x "setup.msi" /qn' -Rules $detection -IntuneWinFilePath .\setup.intunewin

        Creates the app with an MSI detection rule and uploads setup.intunewin.

    .EXAMPLE
        New-IntuneWin32Application -ExistingPackage "MyApp | 00000000-0000-0000-0000-000000000000" -Version "2.0.0" -IntuneWinFilePath .\MyApp-2.0.intunewin

        Creates a new app with the settings of an existing one and uploads the new package.

    .LINK
        https://learn.microsoft.com/graph/api/intune-apps-win32lobapp-create
    #>
    [CmdletBinding(DefaultParameterSetName = 'NewPackage', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Description,

        [version]$Version,

        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [string]$Publisher,

        [string]$Owner,

        [string]$Developer,

        [string]$Notes,

        [string]$PrivacyInformationUrl,

        [string]$InformationUrl,

        [bool]$IsFeatured,

        [ValidateSet("x86", "x64", "arm", "neutral")]
        [string]$ApplicableArchitectures = "x64",

        [int]$MinimumFreeDiskSpaceInMB,

        [int]$MinimumMemoryInMB,

        [int]$MinimumNumberOfProcessors,

        [int]$MinimumCpuSpeedInMHz,

        [ValidateSet("system", "user")]
        [string]$InstallExperienceRunAsAccount = "system",

        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$InstallExperienceDeviceRestartBehavior = "basedOnReturnCode",

        [string]$MinimumSupportedWindowsRelease,

        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [Parameter(Mandatory, ParameterSetName = 'NewPackage')]
        [Parameter(ParameterSetName = 'CloneExistingPackage')]
        [hashtable[]]$Rules,

        [hashtable[]]$ReturnCodes,

        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Leaf)) { throw "The icon '$_' does not exist." }
                if ([System.IO.Path]::GetExtension($_) -notin @('.png', '.jpg', '.jpeg')) { throw "The icon must be a PNG or JPG file." }
                $true
            })]
        [string]$IconFilePath,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IntuneWinFilePath,

        [Parameter(Mandatory, ParameterSetName = 'CloneExistingPackage')]
        [ArgumentCompleter({
                param($CommandName, $ParameterName, $WordToComplete)
                $null = $CommandName, $ParameterName
                if (-not (Get-Command -Name 'Invoke-MgGraphRequest' -ErrorAction SilentlyContinue)) {
                    return
                }
                try {
                    $Response = Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')&`$select=id,displayName" -OutputType PSObject -ErrorAction Stop
                    $Response.value |
                        Where-Object { $_.displayName -like "$($WordToComplete.Trim("'"))*" } |
                        ForEach-Object { "'$($_.displayName) | $($_.id)'" }
                }
                catch {
                    return
                }
            })]
        [ValidateNotNullOrEmpty()]
        [string]$ExistingPackage,

        [ValidateRange(0, 300)]
        [int]$PollIntervalSeconds = 5,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 600
    )

    begin {
        $null = Assert-MgGraphConnection
    }
    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer
        try {
            $Package = Read-IntuneWinPackage -Path $IntuneWinFilePath -ErrorAction Stop

            # Start from the existing app when cloning; bound parameters are applied on top
            $Body = [ordered]@{ '@odata.type' = '#microsoft.graph.win32LobApp' }
            if ($PSCmdlet.ParameterSetName -eq 'CloneExistingPackage') {
                $ExistingId = $ExistingPackage.Split('|')[-1].Trim()
                Write-Verbose "Reading the existing app $ExistingId."
                $Existing = Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceAppManagement/mobileApps/$ExistingId" -OutputType PSObject -ErrorAction Stop
                if ($Existing.'@odata.type' -ne '#microsoft.graph.win32LobApp') {
                    throw "The app '$ExistingId' is not a Win32 app ($($Existing.'@odata.type'))."
                }
                foreach ($Property in 'displayName', 'description', 'publisher', 'owner', 'developer', 'notes', 'privacyInformationUrl', 'informationUrl',
                    'isFeatured', 'installCommandLine', 'uninstallCommandLine', 'applicableArchitectures', 'minimumFreeDiskSpaceInMB', 'minimumMemoryInMB',
                    'minimumNumberOfProcessors', 'minimumCpuSpeedInMHz', 'rules', 'installExperience', 'returnCodes', 'minimumSupportedWindowsRelease') {
                    if ($null -ne $Existing.$Property) {
                        $Body[$Property] = $Existing.$Property
                    }
                }
            }

            $Map = [ordered]@{
                Name                           = 'displayName'
                Description                    = 'description'
                Publisher                      = 'publisher'
                Owner                          = 'owner'
                Developer                      = 'developer'
                Notes                          = 'notes'
                PrivacyInformationUrl          = 'privacyInformationUrl'
                InformationUrl                 = 'informationUrl'
                IsFeatured                     = 'isFeatured'
                InstallCommandLine             = 'installCommandLine'
                UninstallCommandLine           = 'uninstallCommandLine'
                MinimumFreeDiskSpaceInMB       = 'minimumFreeDiskSpaceInMB'
                MinimumMemoryInMB              = 'minimumMemoryInMB'
                MinimumNumberOfProcessors      = 'minimumNumberOfProcessors'
                MinimumCpuSpeedInMHz           = 'minimumCpuSpeedInMHz'
                MinimumSupportedWindowsRelease = 'minimumSupportedWindowsRelease'
            }
            foreach ($Parameter in $Map.Keys) {
                if ($PSBoundParameters.ContainsKey($Parameter)) {
                    $Body[$Map[$Parameter]] = $PSBoundParameters[$Parameter]
                }
            }
            if ($PSBoundParameters.ContainsKey('ApplicableArchitectures') -or -not $Body.Contains('applicableArchitectures')) {
                $Body['applicableArchitectures'] = $ApplicableArchitectures
            }
            if ($PSBoundParameters.ContainsKey('InstallExperienceRunAsAccount') -or $PSBoundParameters.ContainsKey('InstallExperienceDeviceRestartBehavior') -or -not $Body.Contains('installExperience')) {
                $Body['installExperience'] = [ordered]@{
                    '@odata.type'         = '#microsoft.graph.win32LobAppInstallExperience'
                    runAsAccount          = $InstallExperienceRunAsAccount
                    deviceRestartBehavior = $InstallExperienceDeviceRestartBehavior
                }
            }
            if ($PSBoundParameters.ContainsKey('Rules')) {
                $Body['rules'] = @($Rules)
            }
            if (-not @($Body['rules'] | Where-Object { $_.ruleType -eq 'detection' })) {
                throw 'At least one detection rule is required. Create one with New-IntuneWin32Rule -RuleParentType detection.'
            }
            if ($PSBoundParameters.ContainsKey('ReturnCodes')) {
                $Body['returnCodes'] = @($ReturnCodes)
            }
            elseif (-not $Body.Contains('returnCodes')) {
                $Body['returnCodes'] = @(
                    @{ returnCode = 0; type = 'success' }
                    @{ returnCode = 1707; type = 'success' }
                    @{ returnCode = 3010; type = 'softReboot' }
                    @{ returnCode = 1641; type = 'hardReboot' }
                    @{ returnCode = 1618; type = 'retry' }
                )
            }
            if ($Version) {
                $VersionNote = "Version: $Version"
                if ([string]$Body['notes'] -notmatch [regex]::Escape($VersionNote)) {
                    $Body['notes'] = (@([string]$Body['notes'], $VersionNote) | Where-Object { $_ }) -join "`n"
                }
            }
            if ($IconFilePath) {
                $Extension = [System.IO.Path]::GetExtension($IconFilePath).TrimStart('.').ToLowerInvariant()
                if ($Extension -eq 'jpg') {
                    $Extension = 'jpeg'
                }
                $Body['largeIcon'] = [ordered]@{
                    '@odata.type' = '#microsoft.graph.mimeContent'
                    type          = "image/$Extension"
                    value         = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path -Path $IconFilePath).ProviderPath))
                }
            }
            foreach ($Required in 'displayName', 'description', 'publisher', 'installCommandLine', 'uninstallCommandLine') {
                if ([string]::IsNullOrEmpty([string]$Body[$Required])) {
                    throw "The app property '$Required' is empty."
                }
            }
            $Body['fileName'] = Split-Path -Path $IntuneWinFilePath -Leaf
            $Body['setupFilePath'] = $Package.SetupFile

            if (-not $PSCmdlet.ShouldProcess([string]$Body['displayName'], 'Create Intune Win32 app and upload its content')) {
                Invoke-TelemetryCollection @TelemetryArgs -Stage End
                return
            }

            Write-Verbose "Creating the Win32 app '$($Body['displayName'])'."
            $App = Invoke-MgGraphRequest -Method POST -Uri 'v1.0/deviceAppManagement/mobileApps' -Body ($Body | ConvertTo-Json -Depth 10 -Compress) -ContentType 'application/json' -OutputType PSObject -ErrorAction Stop
            try {
                $ContentVersion = Publish-IntuneWin32AppContent -AppId $App.id -IntuneWinPath $IntuneWinFilePath -PollIntervalSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds -ErrorAction Stop
            }
            catch {
                throw "The app '$($App.displayName)' ($($App.id)) was created but its content could not be uploaded: $($_.Exception.Message) Upload it again with Publish-IntuneAppPackage -Force, or delete the app."
            }
            $App | Add-Member -NotePropertyName committedContentVersion -NotePropertyValue $ContentVersion -Force
            $App
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
