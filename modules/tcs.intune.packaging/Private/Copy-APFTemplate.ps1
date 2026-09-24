function Copy-APFTemplate {
    <#
    .SYNOPSIS
        Copies an APF installer template, including its shared files, into a package folder.

    .DESCRIPTION
        Files that are the same in several templates are kept once in Public/Templates/_shared and
        copied into the package when it is built:
          - Write-DeploymentLog.ps1 goes into every package.
          - Detection-Version.ps1 is the detection script of the Files, PowerShellProfile, script-os,
            standalone-application and standalone-exe templates.
          - Detection-TargetAware.ps1 is the detection script of the Application and WindowsFeatures
            templates.
        Exclude applies to the files of the template folder only.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Application', 'Files', 'PowerShellProfile', 'Registry', 'WindowsFeatures', 'script', 'script-os', 'standalone-application', 'standalone-exe')]
        [string]$Template,

        [Parameter(Mandatory)]
        [string]$Destination,

        [string[]]$Exclude
    )

    $TemplateRoot = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'Public/Templates'
    $SharedFolder = Join-Path -Path $TemplateRoot -ChildPath '_shared'

    # Package file name = shared source file name
    $SharedFiles = @{ 'Write-DeploymentLog.ps1' = 'Write-DeploymentLog.ps1' }
    switch ($Template) {
        { $_ -in 'Files', 'PowerShellProfile', 'standalone-application', 'standalone-exe' } {
            $SharedFiles['Intune-D-AppDetection.ps1'] = 'Detection-Version.ps1'
        }
        'script-os' {
            $SharedFiles['Intune-D-Detection.ps1'] = 'Detection-Version.ps1'
        }
        'Application' {
            $SharedFiles['Intune-D-AppDetection.ps1'] = 'Detection-TargetAware.ps1'
        }
        'WindowsFeatures' {
            $SharedFiles['Intune-D-WindowsFeatureDetection.ps1'] = 'Detection-TargetAware.ps1'
        }
    }

    $CopyParameters = @{
        Path        = Join-Path -Path (Join-Path -Path $TemplateRoot -ChildPath $Template) -ChildPath '*'
        Destination = $Destination
        Recurse     = $true
        Force       = $true
        ErrorAction = 'Stop'
    }
    if ($Exclude) {
        $CopyParameters['Exclude'] = $Exclude
    }
    Copy-Item @CopyParameters
    foreach ($Target in $SharedFiles.Keys) {
        Copy-Item -LiteralPath (Join-Path -Path $SharedFolder -ChildPath $SharedFiles[$Target]) -Destination (Join-Path -Path $Destination -ChildPath $Target) -Force -ErrorAction Stop
    }
}
