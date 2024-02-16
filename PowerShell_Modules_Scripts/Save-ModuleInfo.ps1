function Save-ModuleInfo {
    param(
        [string]$path = $PSScriptRoot
    )

    # Get system information
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem

    # Create the file name
    $fileName = "{0}_{1}_{2}_PowerShellModules.json" -f $computerSystem.Manufacturer, $computerSystem.Name, $operatingSystem.Caption
    $fileName = $fileName.Replace(" ", "") # Remove spaces

    # Get the path to the user's Documents directory
    $documentsPath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents")

    # Get the path to the user's Windows PowerShell modules directory
    $windowsPowerShellModulesPath = [System.IO.Path]::Combine($documentsPath, "WindowsPowerShell", "Modules")

    # Get the path to the user's PowerShell Core modules directory
    $powerShellCoreModulesPath = [System.IO.Path]::Combine($documentsPath, "PowerShell", "Modules")

    # Define the paths to include
    $includedWindowsPowerShellModulesPath = $windowsPowerShellModulesPath + "\*"
    $includedPowerShellCoreModulesPath = $powerShellCoreModulesPath + "\*"

    # List all available modules, including only those in the included paths
    $modules = Get-Module -ListAvailable | Where-Object { $_.Path -like $includedWindowsPowerShellModulesPath -or $_.Path -like $includedPowerShellCoreModulesPath }

    # Convert the modules to JSON and save to a file
    $modules | ConvertTo-Json | Set-Content -Path (Join-Path -Path $path -ChildPath $fileName)
}
