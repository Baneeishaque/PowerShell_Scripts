# Run the scoop cache show command and store the output in a variable
$output = & "$(scoop prefix scoop)\bin\scoop.ps1" list
# $output = scoop list

# Iterate over each object in the array
foreach ($object in $output) {
    # Print the type of the object
    Write-Output ("Object: {0}, Type: {1}" -f $object, $object.GetType().FullName)
}
