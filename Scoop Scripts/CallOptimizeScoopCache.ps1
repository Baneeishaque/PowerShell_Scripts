$scriptDirectory = Split-Path -Parent $PSCommandPath

# Import the function from the Optimize-ScoopCache.ps1 script
. "$scriptDirectory\Optimize-ScoopCache.ps1"

# Call the function with dryRun set to true
# Optimize-ScoopCache -dryRun $true
Optimize-ScoopCache
