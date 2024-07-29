function Optimize-ScoopCache {
    <#
    .SYNOPSIS
    Optimizes the Scoop cache by removing outdated entries.

    .DESCRIPTION
    This function checks the Scoop cache for outdated entries and optionally removes them.

    .PARAMETER dryRun
    If specified, the function performs a dry run (no actual removals).

    .EXAMPLE
    Optimize-ScoopCache -dryRun
    # Displays messages indicating which cache entries would be removed.

    .EXAMPLE
    Optimize-ScoopCache
    # Removes outdated cache entries.
    #>

    [CmdletBinding()]
    [OutputType([String[]])]
    param (
        [switch]$dryRun
    )

    # Get the cache show output
    $cacheShowOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" cache show

    # Group cache entries by name and sort by name
    $groupedCache = $cacheShowOutput | Group-Object -Property Name | Sort-Object Name

    # Update Scoop and its buckets
    & "$(scoop prefix scoop)\bin\scoop.ps1" update

    $output = @()

    foreach ($entry in $groupedCache) {
        $appName = $entry.Name

        $searchOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" search $appName
        $filteredSearchOutput = $searchOutput | Where-Object { $_.Name -eq $appName }

        if ($filteredSearchOutput) {
            $versionInCache = $entry.Group[0].Version

            if ($filteredSearchOutput.GetType().Name -eq 'PSCustomObject') {
                $latestVersion = $filteredSearchOutput.Version
                if ($latestVersion -ne $versionInCache) {
                    if ($dryRun) {
                        $output += "Would remove cache for app $appName (latest version: $latestVersion)."
                    }
                    else {
                        & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $appName
                        $output += "Removed cache for app $appName (latest version: $latestVersion)."
                    }
                }
                else {
                    $output += "Cache for app $appName is up-to-date with version $latestVersion."
                }
            }
            else {
                $output += "The type of `$filteredSearchOutput for $appName is not PSCustomObject, it is $($filteredSearchOutput.GetType().Name)."
            }
        }
        else {
            if ($dryRun) {
                $output += "Would remove cache for app $appName as no matching app was found in the search output."
            }
            else {
                & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $appName
                $output += "Removed cache for app $appName as no matching app was found in the search output."
            }
        }
    }

    $output
}
