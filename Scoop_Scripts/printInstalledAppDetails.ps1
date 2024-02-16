# Run the scoop cache show command and store the output in a variable
$output = & "$(scoop prefix scoop)\bin\scoop.ps1" list

# Iterate over each object in the output
foreach ($object in $output) {
    # Extract the Name and Version
    $name = $object.Name
    $bucket = $object.Source

    # Print the Name and Version
    Write-Output ("Name: {0}, Bucket: {1}" -f $name, $bucket)
}
