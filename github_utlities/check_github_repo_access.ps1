#! pwsh
# Interactive script to check GitHub token validity and repository access

# Source the GitHubTokenUtilities.ps1 file to load the functions
. "$PSScriptRoot/GitHubTokenUtilities.ps1"

# Prompt the user to enter their GitHub Personal Access Token
$GitHubToken = Read-Host "Enter your GitHub Personal Access Token"

# Check token validity
if (Test-GitHubTokenValidity -GitHubToken $GitHubToken) {

    # Get Rate Limit Information
    Get-GitHubRateLimit -GitHubToken $GitHubToken

    # Prompt the user to enter the repository full name (owner/repo)
    $RepoFullName = Read-Host "Enter the repository full name (owner/repo, e.g., octocat/Spoon-Knife)"

    # Check repository access
    Test-GitHubRepoAccess -GitHubToken $GitHubToken -RepoFullName $RepoFullName
}
else {
    Write-Host "Exiting script due to invalid token."
}
