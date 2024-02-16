$latestRelease = Invoke-RestMethod -Uri "https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&platform=zip&type=release"
$latestRc = Invoke-RestMethod -Uri "https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&platform=zip&type=rc"
$latestEap = Invoke-RestMethod -Uri "https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&platform=zip&type=eap"

if (([System.Version]$latestRelease.IIU.build -gt [System.Version]$latestRc.IIU.build) -and ([System.Version]$latestRelease.IIU.build -gt [System.Version]$latestEap.IIU.build)) {
    $latestBuildNumber = $latestRelease.IIU.build
    $latestRelease = $latestRelease.IIU.version
}
elseif (([System.Version]$latestRc.IIU.build -gt [System.Version]$latestRelease.IIU.build) -and ([System.Version]$latestRc.IIU.build -gt [System.Version]$latestEap.IIU.build)) {
    $latestRelease = $latestRc.IIU.build
    $latestBuildNumber = $latestRelease
}
else {
    $latestRelease = $latestEap.IIU.build
    $latestBuildNumber = $latestRelease
}

Write-Output "$latestBuildNumber $latestRelease"
