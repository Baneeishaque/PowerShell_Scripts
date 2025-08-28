#!pwsh
# Interactive script to check GitHub rate limit

# Source the GitHubTokenUtilities.ps1 file to load the functions
. "$PSScriptRoot/GitHubTokenUtilities.ps1"

# Prompt the user to enter their GitHub Personal Access Token
$GitHubToken = Read-Host "Enter your GitHub Personal Access Token"

# Check token validity
if (Test-GitHubTokenValidity -GitHubToken $GitHubToken) {
    # Get Rate Limit Information
    Get-GitHubRateLimit -GitHubToken $GitHubToken
}
else {
    Write-Host "Exiting script due to invalid token."
}
