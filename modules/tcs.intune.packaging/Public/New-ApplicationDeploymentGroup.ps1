function New-ApplicationDeploymentGroup {
    <#
    .SYNOPSIS
        Generates, and optionally creates, the Entra ID security groups used to deploy an application with Intune.

    .DESCRIPTION
        The New-ApplicationDeploymentGroup function builds four group names for each application:
          Intune-AG-<Name>-Available, Intune-AG-<Name>-Required, Intune-App-<Name>-Test and
          Intune-App-<Name>-Phase1
        where <Name> is the application name in title case without spaces.

        By default the group list is returned. With -CreateGroups the groups are created in Entra ID
        (existing groups are skipped), optionally added to an administrative unit and given members.
        With -CreateFile the list is also exported to Application-Groups.csv in Destination.

        Creating groups needs the Microsoft.Entra module (Get-EntraGroup, New-EntraGroup,
        Add-EntraGroupMember) and, for -AdminUnitId, Microsoft.Graph.Identity.DirectoryManagement.
        Connect first with Connect-Entra or Connect-MgGraph.

        The alias New-ApplicationDeploymentGroups is kept for compatibility with earlier versions.

    .PARAMETER ApplicationName
        The name(s) of the application(s) for which to create deployment groups. Multiple names can be provided.

    .PARAMETER CreateGroups
        Create the groups in Entra ID.

    .PARAMETER CreateFile
        Export the group list to Application-Groups.csv in Destination.

    .PARAMETER Destination
        The folder for Application-Groups.csv when using -CreateFile. Must be an existing folder.

    .PARAMETER AdminUnitId
        The ID of the Entra ID administrative unit that new groups are added to.

    .PARAMETER AvailableMembers
        Object IDs of the members to add to the Available groups.

    .PARAMETER RequiredMembers
        Object IDs of the members to add to the Required groups.

    .PARAMETER TestMembers
        Object IDs of the members to add to the Test groups.

    .PARAMETER Phase1Members
        Object IDs of the members to add to the Phase1 groups.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        One object per group (Name, GroupName, GroupDescription) when -CreateGroups is not used.

    .EXAMPLE
        New-ApplicationDeploymentGroup -ApplicationName "Microsoft 365 Apps"

        Returns the four group names for Microsoft 365 Apps, for example Intune-AG-Microsoft365Apps-Available.

    .EXAMPLE
        New-ApplicationDeploymentGroup -ApplicationName "Microsoft 365 Apps" -CreateGroups -TestMembers '00000000-0000-0000-0000-000000000001'

        Creates the security groups in Entra ID and adds one member to the Test group.

    .EXAMPLE
        New-ApplicationDeploymentGroup -ApplicationName "Adobe Reader", "Google Chrome" -CreateFile -Destination "C:\Output"

        Returns the group names for Adobe Reader and Google Chrome and writes them to C:\Output\Application-Groups.csv.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ApplicationName,

        [switch]$CreateGroups,

        [Parameter(ParameterSetName = "file")]
        [switch]$CreateFile,

        [Parameter(ParameterSetName = "file")]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Container)) {
                    throw "The path $_ does not exist."
                }
                return $true
            })]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [string]$AdminUnitId,

        [Parameter(Mandatory = $false)]
        [string[]]$AvailableMembers,

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredMembers,

        [Parameter(Mandatory = $false)]
        [string[]]$TestMembers,

        [Parameter(Mandatory = $false)]
        [string[]]$Phase1Members
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
            # Capitalise each word in the application name and remove the spaces
            $textInfo = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo
            $FormattedNames = $ApplicationName | ForEach-Object { ($_.Split(' ') | ForEach-Object { $textInfo.ToTitleCase($_.ToLower()) }) -join '' }
            if ($CreateFile -and [string]::IsNullOrEmpty($Destination)) {
                throw 'Destination is required when CreateFile is used.'
            }
            if ($CreateGroups -and -not (Get-Command -Name 'New-EntraGroup' -ErrorAction SilentlyContinue)) {
                throw 'CreateGroups needs the Microsoft.Entra module (New-EntraGroup). Install it with Install-Module Microsoft.Entra and connect with Connect-Entra.'
            }
        }
        catch {
            $TelemetryFailed = $true
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            throw
        }
    }
    process {
        try {
            # Generate the security group names
            $GroupList = [System.Collections.Generic.List[object]]::new()
            $NameTemplates = @(
                "Intune-AG-{{ApplicationName}}-Available",
                "Intune-AG-{{ApplicationName}}-Required",
                "Intune-App-{{ApplicationName}}-Test",
                "Intune-App-{{ApplicationName}}-Phase1"
            )
            foreach ($NameTemplate in $NameTemplates) {
                foreach ($Application in $FormattedNames) {
                    $GroupList.Add([PSCustomObject]@{
                            Name             = $Application
                            GroupName        = $NameTemplate.Replace('{{ApplicationName}}', $Application)
                            GroupDescription = "Assignment group for the $Application application."
                        })
                }
            }
            $MembersBySuffix = @{
                'Available' = $AvailableMembers
                'Required'  = $RequiredMembers
                'Test'      = $TestMembers
                'Phase1'    = $Phase1Members
            }
            if ($CreateGroups) {
                foreach ($Group in $GroupList) {
                    $GroupName = $Group.GroupName
                    # Test if the group exists first
                    try {
                        $GroupExists = Get-EntraGroup -Filter "displayName eq '$($GroupName.Replace("'", "''"))'" -ErrorAction Stop
                    }
                    catch {
                        Write-Verbose "Could not look up group '$GroupName': $($_.Exception.Message)"
                        $GroupExists = $null
                    }
                    if ($GroupExists) {
                        Write-Output "Group $GroupName already exists in Entra, skipping."
                        continue
                    }
                    if (-not $PSCmdlet.ShouldProcess($GroupName, 'Create Entra ID security group')) {
                        continue
                    }
                    Write-Output "Creating group $GroupName in Entra"
                    try {
                        $newGroup = New-EntraGroup -DisplayName $GroupName -MailEnabled $false -SecurityEnabled $true -MailNickname $GroupName -Description $Group.GroupDescription -ErrorAction Stop
                    }
                    catch {
                        Write-Error "Failed to create group $GroupName. Error: $_"
                        continue
                    }
                    # Assign to the administrative unit if specified
                    if ($AdminUnitId) {
                        try {
                            Add-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $AdminUnitId -DirectoryObjectId $newGroup.Id -ErrorAction Stop
                            Write-Output "Assigned group $($newGroup.Id) to Admin Unit $AdminUnitId"
                        }
                        catch {
                            Write-Warning "Failed to assign group $($newGroup.Id) to Admin Unit ${AdminUnitId}: $_"
                        }
                    }
                    # Add group members based on the group type (the last part of the group name)
                    $Suffix = $GroupName.Split('-')[-1]
                    foreach ($member in @($MembersBySuffix[$Suffix] | Where-Object { $_ })) {
                        try {
                            Add-EntraGroupMember -GroupId $newGroup.Id -MemberId $member -ErrorAction Stop
                            Write-Output "Added member $member to group $GroupName"
                        }
                        catch {
                            Write-Warning "Failed to add member $member to group ${GroupName}: $_"
                        }
                    }
                }
            }
            if ($CreateFile) {
                $CsvPath = Join-Path -Path $Destination -ChildPath 'Application-Groups.csv'
                if ($PSCmdlet.ShouldProcess($CsvPath, 'Export group list')) {
                    $GroupList | Export-Csv -Path $CsvPath -NoTypeInformation -Force
                }
            }
            if (-not $CreateGroups) {
                $GroupList
            }
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
