$entries = git lfs ls-files -l
$counter = 0

foreach ($entry in $entries)
{
    # Write-Output $entry

    $parts = $entry -split ' '
    if ($parts[1] -eq '-' -and $counter -lt 10)
    {
        $concatenatedString = $parts[2..($parts.Length - 1)] -join ' '
        Write-Output $concatenatedString

        git lfs pull --include="$concatenatedString"
        git checkout -- "$concatenatedString"

        $counter++
    }
}
