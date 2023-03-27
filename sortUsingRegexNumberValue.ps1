$myStrings = @("Number 1", "Number 10", "Number 5", "Number 2")
$regexPattern = "Number (\d+)"

# Match against each string using regular expressions
$matchResult = $myStrings | Select-String -Pattern $regexPattern -AllMatches | Foreach-Object {$_.Matches}

# Sort the matches based on the captured group number value
$sortedMatches = $matchResult | Sort-Object {[int]$_.Groups[1].Value}

# Print out the sorted matches
foreach ($match in $sortedMatches) {
    Write-Output $match.Value
}
