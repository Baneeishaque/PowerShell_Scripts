$latestStable = Select-String -InputObject $(Invoke-WebRequest -Uri "https://winscp.net/eng/downloads.php").Content -Pattern 'WinSCP-([\d.]+)-Portable\.zip'
# $latestStable.Matches.Groups

$latestRc = Select-String -InputObject $(Invoke-WebRequest -Uri "https://winscp.net/eng/downloads.php").Content -Pattern 'WinSCP-([\d.]+)\.RC-Portable\.zip'
# $latestRc.Matches.Groups

$latestBeta = Select-String -InputObject $(Invoke-WebRequest -Uri "https://winscp.net/eng/downloads.php").Content -Pattern 'WinSCP-([\d.]+)\.beta-Portable\.zip'
# $latestBeta.Matches.Groups

if ($latestRc.Matches.Groups.Count -eq 0) {
    if ([System.Version]$latestStable.Matches.Groups[1].Value -gt [System.Version]$latestBeta.Matches.Groups[1].Value) {
        $latestRelease = $latestStable.Matches.Groups[1].Value
    }
    else {
        $latestRelease = "$($latestBeta.Matches.Groups[1].Value) %20beta"
    }
}else {
    if ([System.Version]$latestStable.Matches.Groups[1].Value -gt [System.Version]$latestRc.Matches.Groups[1].Value) {
        $latestRelease = $latestStable.Matches.Groups[1].Value
    }
    else {
        $latestRelease = "$($latestRc.Matches.Groups[1].Value) %20RC"
    }
}

Write-Output $latestRelease
