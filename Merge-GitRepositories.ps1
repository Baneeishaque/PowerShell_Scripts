#!pwsh
<#
.SYNOPSIS
    Merges multiple git repositories into a new repo, preserving commit history and resolving file name conflicts.
.DESCRIPTION
    Mirrors the first repo, then cherry-picks commits from subsequent repos, handling file conflicts.
    Uses Common-Utils.ps1 for reusable functions.
.PARAMETER TargetRepoPath
    Path to the new, unified git repository. If not provided, a new repo is created in the current directory.
.PARAMETER SourceRepoPaths
    Array of paths to source repositories to merge.
.PARAMETER SkipVerification
    If true, skips the post-merge verification step. Default: $false.
.EXAMPLE
    ./Merge-GitRepositories.ps1 -SourceRepoPaths "/repo1", "/repo2"
    ./Merge-GitRepositories.ps1 -SourceRepoPaths "/repo1", "/repo2" -SkipVerification $true
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$TargetRepoPath,
    [Parameter(Mandatory)]
    [string[]]$SourceRepoPaths,
    [Parameter(Mandatory=$false)]
    [bool]$SkipVerification = $false
)

# Pre-check for Common-Utils.ps1
$commonUtilsPath = Join-Path $PSScriptRoot "Common-Utils.ps1"
if (-not (Test-Path $commonUtilsPath)) {
    Write-Host "Common-Utils.ps1 not found. Aborting script."
    exit 1
}
. $commonUtilsPath

# Set target repo path
if (-not $TargetRepoPath) {
    $TargetRepoPath = Join-Path (Get-Location) "UnifiedRepo_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Message "No target path provided. Creating new repo at $TargetRepoPath"
}

# Mirror first repo (bare)
$firstRepo = $SourceRepoPaths[0]
$bareRepoPath = "$TargetRepoPath.bare"
git clone --mirror $firstRepo $bareRepoPath

# Create working tree from bare repo
git clone $bareRepoPath $TargetRepoPath

# Track existing files in target repo
$existingFiles = @{}
$fileCounts = @{}

# Populate existing files from first repo
$files = git -C $TargetRepoPath ls-tree -r --name-only HEAD
foreach ($file in $files) { $existingFiles[$file] = $true }

# Use cross-platform temp directory
$tempRoot = [System.IO.Path]::GetTempPath()

# For each subsequent repo
for ($i = 1; $i -lt $SourceRepoPaths.Count; $i++) {
    $repoPath = $SourceRepoPaths[$i]
    if (-not (Test-Path $repoPath)) {
        Write-Message "Source repo path does not exist: $repoPath"
        continue
    }
    $tempRepo = Join-Path $tempRoot ("temp_" + [System.IO.Path]::GetFileName($repoPath) + "_" + [guid]::NewGuid().ToString())
    if (Test-Path $tempRepo) { Remove-Item -Recurse -Force $tempRepo }
    git clone $repoPath $tempRepo
    if (-not (Test-Path $tempRepo)) {
        Write-Message "Failed to clone $repoPath to $tempRepo"
        continue
    }

    $commits = git -C $tempRepo rev-list --reverse HEAD
    if (-not $commits) {
        Write-Message "No commits found in $tempRepo"
        continue
    }

    foreach ($commit in $commits) {
        git -C $tempRepo checkout $commit
        $files = git -C $tempRepo ls-tree -r --name-only $commit

        # Use Resolve-FileNameConflicts for file name conflict resolution
        $resolvedNames = Resolve-FileNameConflicts -FileNames $files

        foreach ($file in $files) {
            $fileName = [System.IO.Path]::GetFileName($file)
            $resolvedName = $resolvedNames[$file]
            if ($fileName -ne $resolvedName) {
                Write-Message "Conflict detected: $fileName. Renaming to $resolvedName in commit $commit."
                git -C $tempRepo mv $file "$resolvedName"
                git -C $tempRepo commit --amend --no-edit
            }
        }

        # Cherry-pick commit into target repo
        $commitMsg = git -C $tempRepo log -1 --format="%s"
        $commitBody = git -C $tempRepo log -1 --format="%b"
        $commitAuthor = git -C $tempRepo log -1 --format="%an <%ae>"
        $commitDate = git -C $tempRepo log -1 --format="%ad" --date=iso

        # Create patch and apply to target repo
        $patchFile = Join-Path $tempRoot ("patch_" + $commit + ".patch")
        git -C $tempRepo format-patch -1 $commit --stdout > $patchFile
        if (Test-Path $patchFile) {
            Get-Content $patchFile | git -C $TargetRepoPath am --committer-date-is-author-date
            Remove-Item -Force $patchFile
        } else {
            Write-Message "Patch file not created for commit $commit"
        }

        # Update existing files
        $files = git -C $TargetRepoPath ls-tree -r --name-only HEAD
        foreach ($file in $files) { $existingFiles[$file] = $true }
    }

    if ($tempRepo -and (Test-Path $tempRepo)) {
        Remove-Item -Recurse -Force $tempRepo
    }
}

# Cleanup bare repo
Remove-Item -Recurse -Force $bareRepoPath

Write-Message "Merge complete. All source repos have been merged into $TargetRepoPath."

# Verification step: compare merged repo with source repos
if (-not $SkipVerification) {
    $compareScript = Join-Path $PSScriptRoot "Compare-GitRepositories.ps1"
    if (Test-Path $compareScript) {
        Write-Message "Starting verification: comparing merged repo to source repos..."
        . $compareScript
        Compare-GitRepositories `
            -TargetRepoPath $TargetRepoPath `
            -ReferenceRepoPaths $SourceRepoPaths `
            -CompareByMessage $true `
            -CompareByTime $true `
            -CompareByAuthor $true `
            -CompareByContent $true
        Write-Message "Verification complete. See above for any missing commits."
    } else {
        Write-Message "Verification script Compare-GitRepositories.ps1 not found. Skipping verification."
    }
} else {
    Write-Message "Verification skipped as per user request."
}
