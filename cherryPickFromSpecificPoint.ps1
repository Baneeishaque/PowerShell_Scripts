#!pwsh
# Usage: .\cherry_pick_commits.ps1 <source_repo> <source_branch> <target_repo> <target_branch>

param (
    [string] $SOURCE_REPO,
    [string] $SOURCE_BRANCH,
    [string] $TARGET_REPO,
    [string] $TARGET_BRANCH
)

# Check if the source repository exists and is a valid Git repository
if (-not (Test-Path -Path $SOURCE_REPO) -or -not (Test-Path -Path (Join-Path $SOURCE_REPO ".git"))) {
    Write-Host "Source repository is not a valid Git repository."
    exit 1
}

# Check if the target repository exists and is a valid Git repository
if (-not (Test-Path -Path $TARGET_REPO) -or -not (Test-Path -Path (Join-Path $TARGET_REPO ".git"))) {
    Write-Host "Target repository is not a valid Git repository."
    exit 1
}

# Check read permission for the source repository
if (-not (Test-Path -Path (Join-Path $SOURCE_REPO ".git\HEAD"))) {
    Write-Host "No read permission for the source repository."
    exit 1
}

# Check read and write permissions for the target repository
if (-not (Test-Path -Path (Join-Path $TARGET_REPO ".git\HEAD")) -or -not (Test-Path -Path (Join-Path $TARGET_REPO ".git\refs\heads\$TARGET_BRANCH"))) {
    Write-Host "No read or write permission for the target repository."
    exit 1
}

# Check if the source repository remote is already added in the target repository
if (git -C $TARGET_REPO remote | Select-String -Pattern "source_repo") {
    Write-Host "The source repository is already added as a remote in the target repository."
    exit 1
}

# Add the source repository as a remote in the target repository
if (-not (git -C $TARGET_REPO remote add source_repo $SOURCE_REPO)) {
    Write-Host "Error adding the source repository as a remote."
    exit 1
}

# Fetch the latest changes from the source branch
if (-not (git -C $TARGET_REPO fetch source_repo $SOURCE_BRANCH)) {
    Write-Host "Error fetching changes from the source repository."
    exit 1
}

# Get the list of commits after the specified commit in the source repository
$COMMIT_HASHES = (git -C $TARGET_REPO log --pretty=format:"%H" "$SOURCE_BRANCH"..source_repo/"$SOURCE_BRANCH")

# Check if there are commits to cherry-pick
if ($COMMIT_HASHES.Count -eq 0) {
    Write-Host "No commits found after the specified commit in the source repository."
    exit 1
}

# Check if any of the commits already exist in the target repository
foreach ($commit_hash in $COMMIT_HASHES) {
    if (git -C $TARGET_REPO rev-parse --quiet --verify $commit_hash) {
        Write-Host "Commit $commit_hash already exists in the target repository."
        exit 1
    }
}

# Confirm the commit hashes and cherry-pick
Write-Host "Commits to cherry-pick:"
foreach ($commit_hash in $COMMIT_HASHES) {
    $choice = Read-Host "Cherry-pick commit $commit_hash? (y/n)"
    if ($choice -eq "y") {
        if (-not (git -C $TARGET_REPO cherry-pick $commit_hash)) {
            Write-Host "Cherry-pick failed for commit $commit_hash."
            exit 1
        }
    }
}

Write-Host "Cherry-picking completed!"
