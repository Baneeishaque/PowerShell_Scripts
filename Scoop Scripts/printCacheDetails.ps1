# Run the scoop show command and store the output in a variable
$showOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" cache show

# Create a hashtable to store the name and version from the show output
$showHashTable = @{}
foreach ($object in $showOutput) {
    # If the name already exists in the hashtable, continue to the next iteration
    if ($showHashTable.ContainsKey($object.Name)) {
        continue
    }

    # Otherwise, add the object to the hashtable
    $showHashTable[$object.Name] = $object
}

# Iterate over each object in the show hashtable
foreach ($name in $showHashTable.Keys) {
    # Get the scoop search output for the app
    $searchOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" search $name

    # Sort the search output by version and select the object with the latest version
    $latestObject = $searchOutput | Sort-Object Version -Descending | Select-Object -First 1

    # Extract the Bucket and the latest Version from the latest object
    $bucket = $latestObject.Source
    $latestVersion = $latestObject.Version

    # Get the Version from the show hashtable
    $version = $showHashTable[$name].Version

    # Print the Name, Version from the show output, latest Version, and Bucket
    Write-Output ("Name: {0}, Version: {1}, Latest Version: {2}, Bucket: {3}" -f $name, $version, $latestVersion, $bucket)
}
