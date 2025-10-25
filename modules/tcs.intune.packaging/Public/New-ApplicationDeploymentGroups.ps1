function New-ApplicationDeploymentGroups {
    <#
    .SYNOPSIS
        Creates security groups for application deployment in Intune.

    .DESCRIPTION
        The New-ApplicationDeploymentGroups function generates security group names for managing application deployments
        in Intune. It can create groups for different deployment scenarios (Available, Required, Test, Phase1) and
        optionally create them in Azure AD or export them to a CSV file.

    .PARAMETER ApplicationName
        The name(s) of the application(s) for which to create deployment groups. Multiple names can be provided.

    .PARAMETER CreateGroups
        Switch to create the groups in Azure AD.

    .PARAMETER CreateFile
        Switch to export the group list to a CSV file.

    .PARAMETER Destination
        The destination folder path for the CSV file when using -CreateFile. Must be a valid container path.

    .PARAMETER AdminUnitId
        The Administrative Unit ID in Azure AD where groups should be created.

    .PARAMETER AvailableMembers
        Array of member IDs to add to the Available deployment groups.

    .PARAMETER RequiredMembers
        Array of member IDs to add to the Required deployment groups.

    .PARAMETER TestMembers
        Array of member IDs to add to the Test deployment groups.

    .PARAMETER Phase1Members
        Array of member IDs to add to the Phase1 deployment groups.

    .EXAMPLE
        New-ApplicationDeploymentGroups -ApplicationName "Microsoft 365 Apps" -CreateGroups
        
        Creates security groups in Azure AD for Microsoft 365 Apps deployment.

    .EXAMPLE
        New-ApplicationDeploymentGroups -ApplicationName "Adobe Reader", "Google Chrome" -CreateFile -Destination "C:\Output"
        
        Generates a CSV file with group names for Adobe Reader and Google Chrome.

    .OUTPUTS
        PSObject containing the generated group information.

    .LINK
        https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html
    #>
    [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://PENDIINGHOST/tcs.intune.packaging/docs/New-APFDeployment.html')]
    [OutputType([psobject])]
    [OutputType([psobject], ParameterSetName = "file")]
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
        $Destination,

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
        # sanitize application names by capitalizing each work and removing spaces
        # Capatalize each word in the application name
        $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
        $textInfo = $cultureInfo.TextInfo
        $FormatedNames = $ApplicationName | ForEach-Object { $($_.Split(" ") | ForEach-Object { $textInfo.ToTitleCase($_.ToLower()) }) -Join "" }
    } 
    process {
        # Generate the security group names
        $GroupList = @()
        $NameTemplates = @(
            "Intune-AG-{{ApplicationName}}-Available",
            "Intune-AG-{{ApplicationName}}-Required",
            "Intune-App-{{ApplicationName}}-Test",
            "Intune-App-{{ApplicationName}}-Phase1"
        )
        foreach ($NameTemplate in $NameTemplates) {
            foreach ($Application in $FormatedNames) {
                $obj = [PSCustomObject]@{
                    Name             = $Application
                    GroupName        = $NameTemplate -replace "{{ApplicationName}}", $Application
                    GroupDescription = "Assignment group for the $Application application."
                }
                $GroupList += $obj
            }
        }
        if ($CreateGroups) {
            foreach ($Group in $GroupList) {
                # Test if group exists first
                try {
                    $name = $Group.GroupName
                    $GroupExists = Get-EntraGroup -Filter "displayName eq '$Name'" -ErrorAction Stop
                }
                catch {
                    $GroupExists = $null
                }
                if ($GroupExists) {
                    Write-Output "Group $($Group.GroupName) already exists in Entra, skipping."
                    continue
                }
                else {
                    Write-Output "Creating group $($Group.GroupName) in Entra"
                    try {
                        $newGroup = New-EntraGroup -DisplayName $Group.GroupName -MailEnabled $false -SecurityEnabled $true -MailNickname $Group.GroupName -Description $Group.GroupDescription -ErrorAction Stop
                        # Assign to Admin Unit if specified
                        if ($AdminUnitId) {
                            try {
                                Add-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $AdminUnitId -DirectoryObjectId $newGroup.Id
                                Write-Output "Assigned group $($newGroup.Id) to Admin Unit $AdminUnitId"
                            } catch {
                                Write-Warning "Failed to assign group $($newGroup.Id) to Admin Unit ${AdminUnitId}: $_"
                            }
                        }
                        # Add group members based on group type
                        $groupType = $Group.GroupName
                        if ($groupType -match '-Available$' -and $AvailableMembers) {
                            foreach ($member in $AvailableMembers) {
                                try {
                                    Add-EntraGroupMember -GroupId $newGroup.Id -DirectoryObjectId $member
                                    Write-Output "Added member $member to group $($newGroup.GroupName)"
                                } catch {
                                    Write-Warning "Failed to add member $member to group $($newGroup.GroupName): $_"
                                }
                            }
                        } elseif ($groupType -match '-Required$' -and $RequiredMembers) {
                            foreach ($member in $RequiredMembers) {
                                try {
                                    Add-EntraGroupMember -GroupId $newGroup.Id -DirectoryObjectId $member
                                    Write-Output "Added member $member to group $($newGroup.GroupName)"
                                } catch {
                                    Write-Warning "Failed to add member $member to group $($newGroup.GroupName): $_"
                                }
                            }
                        } elseif ($groupType -match '-Test$' -and $TestMembers) {
                            foreach ($member in $TestMembers) {
                                try {
                                    Add-EntraGroupMember -GroupId $newGroup.Id -DirectoryObjectId $member
                                    Write-Output "Added member $member to group $($newGroup.GroupName)"
                                } catch {
                                    Write-Warning "Failed to add member $member to group $($newGroup.GroupName): $_"
                                }
                            }
                        } elseif ($groupType -match '-Phase1$' -and $Phase1Members) {
                            foreach ($member in $Phase1Members) {
                                try {
                                    Add-EntraGroupMember -GroupId $newGroup.Id -DirectoryObjectId $member
                                    Write-Output "Added member $member to group $($newGroup.GroupName)"
                                } catch {
                                    Write-Warning "Failed to add member $member to group $($newGroup.GroupName): $_"
                                }
                            }
                        }
                    }
                    catch {
                        Write-Error "Failed to create group $($Group.GroupName). Error: $_"
                        continue
                    }
                }
            }
        }
        if ($CreateFile) {
            $GroupList | Export-Csv -Path "$Destination\Application-Groups.csv"
        }
        if (-Not $CreateGroups) {
            $GroupList
        }
    } 
    end {

    }
}
