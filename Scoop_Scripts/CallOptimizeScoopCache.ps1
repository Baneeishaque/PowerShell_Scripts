$scriptDirectory = Split-Path -Parent $PSCommandPath

# Import the functions from the Optimize-ScoopCache.ps1 script
. "$scriptDirectory\Optimize-ScoopCache.ps1"

# Call Optimize-ScoopCache with dryRun
Optimize-ScoopCache -dryRun
