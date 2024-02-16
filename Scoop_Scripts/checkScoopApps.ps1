# Get the current directory
$dir = Get-Location

# Get all directories starting with 'Scoop'
$scoopDirs = Get-ChildItem -Path $dir -Directory | Where-Object { $_.Name -like "Scoop*" }

# For each 'Scoop' directory
foreach ($scoopDir in $scoopDirs) {

    Write-Output "`n$($scoopDir.FullName)"
    Write-Output '------------------------'

    # Get the 'bucket' directory
    $bucketDir = Join-Path -Path $scoopDir.FullName -ChildPath "bucket"

    # If the 'bucket' directory exists
    if (Test-Path -Path $bucketDir) {
        # Get all JSON files in the 'bucket' directory
        $jsonFiles = Get-ChildItem -Path $bucketDir -File -Filter "*.json"

        # For each JSON file
        foreach ($jsonFile in $jsonFiles) {
            # Read the JSON file
            $jsonContent = Get-Content -Path $jsonFile.FullName -Raw

            # Parse the JSON content
            $jsonObject = $jsonContent | ConvertFrom-Json

            # If the 'homepage' field exists
            if ($jsonObject.PSObject.Properties.Name -contains "homepage") {

                Write-Output "$(Split-Path $jsonFile.FullName -Leaf | % { [IO.Path]::GetFileNameWithoutExtension($_) }) $($jsonObject.homepage) $($jsonObject.version)"
            }
        }
    }
}
