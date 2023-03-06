$webData = Invoke-WebRequest -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
$releases = ConvertFrom-Json $webData.content
$releases | get-member
