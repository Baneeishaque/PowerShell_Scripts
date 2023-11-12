$latestRelease = Invoke-RestMethod -Uri "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&platform=zip&type=release"
$latestRc = Invoke-RestMethod -Uri "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&platform=zip&type=rc"
$latestEap = Invoke-RestMethod -Uri "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&platform=zip&type=eap"

if (([System.Version]$latestRelease.PCP.build -gt [System.Version]$latestRc.PCP.build) -and ([System.Version]$latestRelease.PCP.build -gt [System.Version]$latestEap.PCP.build)) {
    $latestRelease = $latestRelease.PCP.version
    $latestBuildNumber = $latestRelease.PCP.build
}
elseif (([System.Version]$latestRc.PCP.build -gt [System.Version]$latestRelease.PCP.build) -and ([System.Version]$latestRc.PCP.build -gt [System.Version]$latestEap.PCP.build)) {
    $latestRelease = $latestRc.PCP.build
    $latestBuildNumber = $latestRelease
}
else {
    $latestRelease = $latestEap.PCP.build
    $latestBuildNumber = $latestRelease
}

Write-Output "$latestBuildNumber $latestRelease"
