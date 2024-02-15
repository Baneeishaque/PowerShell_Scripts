# Run the scoop cache show command and store the output in a variable
$cacheShowOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" cache show

# Run the scoop list command and store the output in a variable
$listOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" list

# Create a hashtable to store the name and bucket from the list output
$listHashTable = @{}
foreach ($object in $listOutput) {
    $listHashTable[$object.Name] = $object.Source
}

# Iterate over each object in the cache show output
foreach ($object in $cacheShowOutput) {
    # Extract the Name and Version
    $name = $object.Name
    $version = $object.Version

    # Check if the name exists in the list hashtable
    if ($listHashTable.ContainsKey($name)) {
        # If it exists, print the Name, Version, and Bucket
        $bucket = $listHashTable[$name]
        Write-Output ("Name: {0}, Version: {1}, Bucket: {2}" -f $name, $version, $bucket)
    } else {
        # If it doesn't exist, get the scoop search output for the app
        $searchOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" search $name

        # Sort the search output by version and select the object with the latest version
        $latestObject = $searchOutput | Sort-Object Version -Descending | Select-Object -First 1

        # Extract the Bucket from the latest object
        $bucket = $latestObject.Source

        # Print the Name, Version, and Bucket
        Write-Output ("Name: {0}, Version: {1}, Bucket: {2}" -f $name, $version, $bucket)
    }
}
