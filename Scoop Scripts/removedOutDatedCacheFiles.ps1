# Set dry-run option
$dryRun = $true

# Run the scoop cache show command and store the output in a variable
$cacheShowOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" cache show

# Create a hashtable to store the name and version from the cache show output
$cacheShowHashTable = @{}
foreach ($object in $cacheShowOutput) {
    # If the name already exists in the hashtable, continue to the next iteration
    if ($cacheShowHashTable.ContainsKey($object.Name)) {
        continue
    }

    # Otherwise, add the object to the hashtable
    $cacheShowHashTable[$object.Name] = $object
}

# Sort the hashtable by key (app name)
$sortedHashTable = $cacheShowHashTable.GetEnumerator() | Sort-Object Key

# Iterate over each object in the sorted hashtable
foreach ($entry in $sortedHashTable) {
    # Get the scoop search output for the app
    $searchOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" search $entry.Key

    # Filter the search output for objects where the name is exactly the same as the app name
    $filteredSearchOutput = $searchOutput | Where-Object { $_.Name -eq $entry.Key }

    # If no matching app is found in the search output, print a message that the cache file for the app would be removed
    if ($filteredSearchOutput.Count -eq 0) {
        if ($dryRun) {
            Write-Output ("Would remove cache for app {0} as no matching app was found in the search output." -f $entry.Key)
        } else {
            & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $entry.Key
            Write-Output ("Removed cache for app {0} as no matching app was found in the search output." -f $entry.Key)
        }
        continue
    }

    # Sort the filtered search output by version (as Version objects) and select the object with the latest version
    $latestObject = $filteredSearchOutput | Sort-Object {[Version] $_.Version} -Descending | Select-Object -First 1

    # Extract the Bucket and the latest Version from the latest object
    $bucket = $latestObject.Source
    $latestVersion = $latestObject.Version

    # Get the Version from the cache show hashtable
    $version = $entry.Value.Version

    # If the latest version is not in the cache, print a message that the cache file for the app would be removed
    if ([Version] $version -lt [Version] $latestVersion) {
        if ($dryRun) {
            Write-Output ("Would remove cache for app {0} as the latest version {1} was not in the cache." -f $entry.Key, $latestVersion)
        } else {
            & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $entry.Key
            Write-Output ("Removed cache for app {0} as the latest version {1} was not in the cache." -f $entry.Key, $latestVersion)
        }
    }

    # Print the Name, Version from the cache show output, latest Version, and Bucket
    Write-Output ("Name: {0}, Version: {1}, Latest Version: {2}, Bucket: {3}" -f $entry.Key, $version, $latestVersion, $bucket)
}
