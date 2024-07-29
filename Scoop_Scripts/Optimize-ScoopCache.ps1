function Optimize-ScoopCache {

    [OutputType([String[]])]

    param(
        [bool]$dryRun = $true
    )

    $output = @()

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

    # Update scoop & it's buckets
    & "$(scoop prefix scoop)\bin\scoop.ps1" update

    # Iterate over each object in the sorted hashtable
    foreach ($entry in $sortedHashTable) {

        # Get the scoop search output for the app
        $searchOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" search $entry.Key

        # Filter the search output for objects where the name is exactly the same as the app name
        $filteredSearchOutput = $searchOutput | Where-Object { $_.Name -eq $entry.Key }

        # If no matching app is found in the search output, print a message that the cache file for the app would be removed
        if ($filteredSearchOutput.Count -eq 0) {

            if ($dryRun) {

                $output += ('Would remove cache for app {0} as no matching app was found in the search output.' -f $entry.Key)
            }
            else {

                & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $entry.Key
                $output += ('Removed cache for app {0} as no matching app was found in the search output.' -f $entry.Key)
            }
            continue
        }

        # Write-Output ('{0} {1}' -f $entry.Key, $filteredSearchOutput.GetType().Name)

        if ($filteredSearchOutput.GetType().Name -eq 'PSCustomObject') {

            # Extract the Bucket and the latest Version from the latest object
            $latestVersion = $filteredSearchOutput.Version

            # Get the Version from the cache show hashtable
            $version = $entry.Value.Version

            # If the latest version is not in the cache, print a message that the cache file for the app would be removed
            if ($latestVersion -eq $version) {

                $output += ('Cache for app {0} is up-to-date with the latest version {1}.' -f $entry.Key, $latestVersion)
            }
            else {

                if ($dryRun) {

                    $output += ('Would remove cache for app {0} as the latest version {1} was not in the cache.' -f $entry.Key, $latestVersion)
                }
                else {

                    & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $entry.Key
                    $output += ('Removed cache for app {0} as the latest version {1} was not in the cache.' -f $entry.Key, $latestVersion)
                }
            }
        }
        else {

            $output += ('The type of `$filteredSearchOutput for {0} is not PSCustomObject, it is {1}' -f $entry.Key, $filteredSearchOutput.GetType().Name)
        }
    }

    $output
}
