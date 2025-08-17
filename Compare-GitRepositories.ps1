<#
.SYNOPSIS
    Compares commits in reference git repositories against a target repository.
.DESCRIPTION
    For each commit in reference repos, checks if an equivalent commit exists in the target repo.
    Comparison criteria are customizable: hash, message, time, author, content.
.PARAMETER TargetRepoPath
    Path to the target git repository.
.PARAMETER ReferenceRepoPaths
    Array of reference git repository paths.
.PARAMETER CompareByHash
    Compare by commit hash (default: $false).
.PARAMETER CompareByMessage
    Compare by commit message (default: $true).
.PARAMETER CompareByTime
    Compare by commit time (default: $true).
.PARAMETER CompareByAuthor
    Compare by commit author (default: $true).
.PARAMETER CompareByContent
    Compare by commit content hash (default: $true).
.EXAMPLE
    ./Compare-GitRepositories.ps1 -TargetRepoPath "/repo1" -ReferenceRepoPaths "/repo2", "/repo3"
#>

function Compare-GitRepositories {
    param (
        [Parameter(Mandatory)]
        [string]$TargetRepoPath,
        [Parameter(Mandatory)]
        [string[]]$ReferenceRepoPaths,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByHash = $false,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByMessage = $true,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByTime = $true,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByAuthor = $true,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByContent = $true
    )

    # Pre-check for Common-Utils.ps1
    $commonUtilsPath = Join-Path $PSScriptRoot "Common-Utils.ps1"
    if (-not (Test-Path $commonUtilsPath)) {
        Write-Host "Common-Utils.ps1 not found. Aborting script."
        exit 1
    }
    . $commonUtilsPath

    function Get-CommitInfo {
        param([string]$RepoPath)
        $commits = git -C $RepoPath log --pretty=format:"%H|%an|%ae|%ad|%s" --date=iso
        $commitInfos = @()
        foreach ($line in $commits) {
            $parts = $line -split "\|", 5
            $hash = $parts[0]
            $author = $parts[1]
            $email = $parts[2]
            $date = $parts[3]
            $msg = $parts[4]
            $contentHash = git -C $RepoPath show $hash --pretty=format:"" --no-patch | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash
            $commitInfos += [PSCustomObject]@{
                Hash = $hash
                Author = $author
                Email = $email
                Date = $date
                Message = $msg
                ContentHash = $contentHash
            }
        }
        return $commitInfos
    }

    Write-Message "Comparing reference repos to target repo: $TargetRepoPath"

    $targetCommits = Get-CommitInfo -RepoPath $TargetRepoPath

    foreach ($refRepo in $ReferenceRepoPaths) {
        Write-Message "Checking reference repo: $refRepo"
        $refCommits = Get-CommitInfo -RepoPath $refRepo
        $missingCommits = @()

        foreach ($refCommit in $refCommits) {
            $found = $false
            foreach ($targetCommit in $targetCommits) {
                $match = $true
                if ($CompareByHash -and ($refCommit.Hash -ne $targetCommit.Hash)) { $match = $false }
                if ($CompareByMessage -and ($refCommit.Message -ne $targetCommit.Message)) { $match = $false }
                if ($CompareByTime -and ($refCommit.Date -ne $targetCommit.Date)) { $match = $false }
                if ($CompareByAuthor -and ($refCommit.Author -ne $targetCommit.Author)) { $match = $false }
                if ($CompareByContent -and ($refCommit.ContentHash -ne $targetCommit.ContentHash)) { $match = $false }
                if ($match) { $found = $true; break }
            }
            if (-not $found) { $missingCommits += $refCommit }
        }

        Write-Message "Reference repo [$refRepo] missing in target [$TargetRepoPath]: $($missingCommits.Count) commits"
        foreach ($commit in $missingCommits) {
            Write-Message "Missing: $($commit.Hash) | $($commit.Author) | $($commit.Date) | $($commit.Message)"
        }
    }

    Write-Message "Comparison complete."
}

# If run directly, call the function with param block
if ($MyInvocation.InvocationName -eq $null -or $MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [Parameter(Mandatory)]
        [string]$TargetRepoPath,
        [Parameter(Mandatory)]
        [string[]]$ReferenceRepoPaths,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByHash = $false,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByMessage = $true,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByTime = $true,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByAuthor = $true,
        [Parameter(Mandatory=$false)]
        [bool]$CompareByContent = $true
    )
    Compare-GitRepositories `
        -TargetRepoPath $TargetRepoPath `
        -ReferenceRepoPaths $ReferenceRepoPaths `
        -CompareByHash $CompareByHash `
        -CompareByMessage $CompareByMessage `
        -CompareByTime $CompareByTime `
        -CompareByAuthor $CompareByAuthor `
        -CompareByContent $CompareByContent
}
