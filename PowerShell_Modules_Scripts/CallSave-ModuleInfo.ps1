#!pwsh
$scriptDirectory = Split-Path -Parent $PSCommandPath

# Dot source the script file that contains the function
. "$scriptDirectory\Save-ModuleInfo.ps1"

# Now you can call the function
# Save-ModuleInfo

# Or call the function with a specific path
Save-ModuleInfo -path "C:\Lab_Data\configurations-private\PowerShell"
