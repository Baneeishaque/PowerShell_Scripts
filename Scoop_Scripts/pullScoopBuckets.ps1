# Get the path to the Scoop buckets directory
$bucketPath = Join-Path $env:USERPROFILE "scoop\buckets"

# Get all the directories in the bucket directory
$directories = Get-ChildItem -Path $bucketPath -Directory

# Loop through each directory and run git pull
foreach ($dir in $directories) {
    Write-Host "Updating $($dir.Name) bucket..."
    Set-Location -Path $dir.FullName
    git pull
    Write-Host ""
}

# Return to the original location
Set-Location -Path $bucketPath
