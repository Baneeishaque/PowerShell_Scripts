foreach ($entry in $(git lfs ls-files -l | Select-Object -First 10))
{
    # Split the entry based on ' - '
    $parts = $entry -split ' - '

    # Concatenate the elements excluding the first one as a single string
    $concatenatedString = $parts[1..($parts.Length - 1)] -join ' - '

    Write-Output $parts[0]
    Write-Output $concatenatedString

    git lfs fetch --include=$concatenatedString
    git checkout $concatenatedString
}
