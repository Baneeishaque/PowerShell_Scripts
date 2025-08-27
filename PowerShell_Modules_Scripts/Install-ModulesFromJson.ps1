#!pwsh
function Install-ModulesFromJson {
    param(
        [string]$fileName
    )

    # If no file name is provided, generate a default one
    if (-not $fileName) {
        # Get system information
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem

        # Create the file name
        $fileName = "{0}_{1}_{2}_PowerShellModules.json" -f $computerSystem.Manufacturer, $computerSystem.Name, $operatingSystem.Caption
        $fileName = $fileName.Replace(" ", "") # Remove spaces
    }

    # Read the JSON file and convert it to PowerShell objects
    $modules = Get-Content -Path $fileName | ConvertFrom-Json

    # Iterate over each module and install it
    foreach ($module in $modules) {
        Install-Module -Name $module.Name
    }
}
