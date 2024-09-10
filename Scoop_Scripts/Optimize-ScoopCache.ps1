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
            foreach ($cacheItem in $entry.Group) {
                $versionInCache = $cacheItem.Version

                if ($filteredSearchOutput -is [System.Array]) {
                    # Multiple sources found; check if the app is installed
                    $listOutput = & "$(scoop prefix scoop)\bin\scoop.ps1" list
                    $installedApp = $listOutput | Where-Object { $_.Name -eq $appName }

                    if ($installedApp) {
                        $installedVersion = $installedApp.Version
                        $installedSource = $installedApp.Source

                        foreach ($source in $filteredSearchOutput) {
                            if ($source.Source -eq $installedSource) {
                                $latestVersion = $source.Version
                                if ($latestVersion -ne $versionInCache) {
                                    if ($dryRun) {
                                        $output += "Would remove cache for app $appName (version in cache: $versionInCache, latest version: $latestVersion)."
                                    }
                                    else {
                                        & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $appName
                                        $output += "Removed cache for app $appName (version in cache: $versionInCache, latest version: $latestVersion)."
                                    }
                                }
                                else {
                                    $output += "Cache for app $appName is up-to-date with version $latestVersion."
                                }
                            }
                        }
                    }
                    else {
                        # App not installed, check every source
                        $versionMatches = $false
                        foreach ($source in $filteredSearchOutput) {
                            $latestVersion = $source.Version
                            if ($latestVersion -eq $versionInCache) {
                                $versionMatches = $true
                                $output += "Cache for app $appName is up-to-date with version $latestVersion (from $($source.Source))."
                            }
                        }
                        if ($versionMatches) {
                            foreach ($source in $filteredSearchOutput) {
                                if ($source.Version -ne $versionInCache) {
                                    $output += "Another version of $appName exists in $($source.Source) (version: $($source.Version))."
                                }
                            }
                        }
                        else {
                            if ($dryRun) {
                                $output += "Would remove cache for app $appName (version in cache: $versionInCache)."
                            }
                            else {
                                & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $appName
                                $output += "Removed cache for app $appName (version in cache: $versionInCache)."
                            }
                        }
                    }
                }
                elseif ($filteredSearchOutput -is [PSCustomObject]) {
                    # Single source found
                    $latestVersion = $filteredSearchOutput.Version
                    if ($latestVersion -ne $versionInCache) {
                        if ($dryRun) {
                            $output += "Would remove cache for app $appName (version in cache: $versionInCache, latest version: $latestVersion)."
                        }
                        else {
                            & "$(scoop prefix scoop)\bin\scoop.ps1" cache rm $appName
                            $output += "Removed cache for app $appName (version in cache: $versionInCache, latest version: $latestVersion)."
                        }
                    }
                    else {
                        $output += "Cache for app $appName is up-to-date with version $latestVersion."
                    }
                }
                else {
                    $output += "Unexpected type for `$filteredSearchOutput for $appName."
                }
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
