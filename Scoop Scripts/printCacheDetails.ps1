# Run the scoop cache show command and store the output in a variable
$output = scoop cache show

# Iterate over each object in the output
foreach ($object in $output) {
    # Extract the Name and Version
    $name = $object.Name
    $version = $object.Version

    # Print the Name and Version
    Write-Output ("Name: {0}, Version: {1}" -f $name, $version)
}
