function Get-MSIProperty {
    <#
    .SYNOPSIS
        Reads the Property table of a Windows Installer (.msi) database.

    .DESCRIPTION
        The Get-MSIProperty function opens an MSI database read-only with the WindowsInstaller.Installer
        COM object and returns every row of its Property table (for example ProductName, ProductVersion,
        ProductCode and Manufacturer) as the properties of a single object.

        This function needs Windows, because it uses the Windows Installer COM object.
        The alias Get-MSIProperties is kept for compatibility with earlier versions.

    .PARAMETER Path
        The path to the .msi file. Accepts pipeline input, including FileInfo objects from Get-ChildItem.

    .INPUTS
        System.String
        System.IO.FileInfo

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .EXAMPLE
        Get-MSIProperty -Path .\setup.msi | Select-Object ProductName, ProductVersion, ProductCode

        Returns the product name, version and product code of setup.msi.

    .EXAMPLE
        Get-ChildItem -Path C:\Installers -Filter *.msi | Get-MSIProperty

        Returns the properties of every MSI file in C:\Installers.

    .NOTES
        Author: Nigel Tatschner
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'MSI database file name')]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    throw "Could not find $_"
                }
                $true
            })]
        [Alias('Filename', 'MSIDbName', 'Database', 'Msi', 'FullName')]
        [string]$Path
    )
    process {
        $TelemetryArgs = @{
            ModuleName    = $MyInvocation.MyCommand.Module.Name
            ModuleVersion = [string]$MyInvocation.MyCommand.Module.Version
            CommandName   = $MyInvocation.MyCommand.Name
            ExecutionID   = [guid]::NewGuid().ToString()
        }
        Invoke-TelemetryCollection @TelemetryArgs -Stage Start -ClearTimer

        $WindowsInstaller = $null
        $Database = $null
        $View = $null
        try {
            $FullPath = (Get-Item -Path $Path -ErrorAction Stop).FullName
            $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer -ErrorAction Stop
            # Open mode 0 = msiOpenDatabaseModeReadOnly
            $Database = $WindowsInstaller.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $WindowsInstaller, @($FullPath, 0))
            $View = $Database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $Database, @('SELECT Property, Value FROM Property'))
            $null = $View.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $View, $null)

            $Results = [ordered]@{}
            $Row = $View.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $View, $null)
            while ($null -ne $Row) {
                $Name = $Row.GetType().InvokeMember('StringData', 'GetProperty', $null, $Row, 1)
                $Value = $Row.GetType().InvokeMember('StringData', 'GetProperty', $null, $Row, 2)
                $Results[$Name] = $Value
                $Row = $View.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $View, $null)
            }
            $null = $View.GetType().InvokeMember('Close', 'InvokeMethod', $null, $View, $null)

            [PSCustomObject]$Results
            Invoke-TelemetryCollection @TelemetryArgs -Stage End
        }
        catch {
            Invoke-TelemetryCollection @TelemetryArgs -Stage End -Failed $true -Exception $_
            Write-Error -Message "Failed to read the MSI database '$Path': $($_.Exception.Message)" -Exception $_.Exception
        }
        finally {
            # Release the COM objects so the MSI file is not left locked
            foreach ($ComObject in @($View, $Database, $WindowsInstaller)) {
                if ($null -ne $ComObject) {
                    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ComObject)
                }
            }
        }
    }
}
