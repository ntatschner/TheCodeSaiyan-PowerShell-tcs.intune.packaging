function Test-IntuneAppAssignmentSetting {
    <#
    .SYNOPSIS
        Throws when assignment settings are incomplete; used before anything is created.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('User-Group', 'Device-Group', 'All-Users', 'All-Devices')]
        [string]$AssignmentType,

        [string]$AssignmentGroup,

        [ValidateSet('required', 'available', 'uninstall')]
        [string]$Intent = 'required',

        [string]$FilterRuleType,

        [string]$FilterRule
    )

    if ($AssignmentType -in 'User-Group', 'Device-Group' -and [string]::IsNullOrWhiteSpace($AssignmentGroup)) {
        throw "AssignmentType $AssignmentType needs AssignmentGroup (the group ID or display name)."
    }
    if ($AssignmentType -in 'All-Users', 'All-Devices' -and -not [string]::IsNullOrWhiteSpace($AssignmentGroup)) {
        throw "AssignmentType $AssignmentType does not use AssignmentGroup; use User-Group or Device-Group to assign to '$AssignmentGroup'."
    }
    if ([string]::IsNullOrWhiteSpace($FilterRule) -ne [string]::IsNullOrWhiteSpace($FilterRuleType)) {
        throw 'FilterRule and FilterRuleType must be used together.'
    }
    if ($FilterRuleType -and $FilterRuleType -notin 'Include', 'Exclude') {
        throw "FilterRuleType must be Include or Exclude, not '$FilterRuleType'."
    }
}
