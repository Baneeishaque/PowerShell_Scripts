#!pwsh
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
$releases | get-member
$releases.assets.name
