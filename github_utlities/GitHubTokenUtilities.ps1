#! pwsh
# GitHubTokenUtilities.ps1

# Function to check if a GitHub token is valid
function Test-GitHubTokenValidity {
    param (
        [string]$GitHubToken
    )

    $ApiUrl = "https://api.github.com/user"
    $Headers = @{
        "Authorization" = "Bearer $GitHubToken"
    }

    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Get
        Write-Host "Token is valid for user: $($Response.login)"
        return $true  # Token is valid
    }
    catch {
        Write-Host "Token is invalid."
        Write-Host "Error: $($_.Exception.Message)"
        return $false # Token is invalid
    }
}

# Function to check GitHub API rate limit
function Get-GitHubRateLimit {
    param (
        [string]$GitHubToken
    )

    $ApiUrl = "https://api.github.com/rate_limit"
    $Headers = @{
        "Authorization" = "Bearer $GitHubToken"
    }

    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Get
        $Remaining = $Response.rate.remaining
        $ResetTime = $Response.rate.reset
        $ResetDateTime = [datetimeoffset]::FromUnixTimeSeconds($ResetTime)
        Write-Host "Remaining: $Remaining"
        Write-Host "Reset Time: $($ResetDateTime.LocalDateTime)"
        return $Response.rate # Return the entire rate object for more info, if needed
    }
    catch {
        Write-Host "Error getting rate limit: $($_.Exception.Message)"
        return $null
    }
}

# Function to check GitHub repository access
function Test-GitHubRepoAccess {
    param (
        [string]$GitHubToken,
        [string]$RepoFullName  # e.g., "owner/repo"
    )

    $ApiRepoUrl = "https://api.github.com/repos/$RepoFullName"
    $Headers = @{
        "Authorization" = "Bearer $GitHubToken"
    }

    try {
        $RepoResponse = Invoke-RestMethod -Uri $ApiRepoUrl -Headers $Headers -Method Get
        Write-Host "Token has access to the repository: $($RepoResponse.full_name)"
        return $true # Token has access
    }
    catch {
        Write-Host "Token does NOT have access to the repository."
        Write-Host "Error: $($_.Exception.Message)"
        return $false # Token does not have access
    }
}
