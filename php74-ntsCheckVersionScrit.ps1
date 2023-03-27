$latestVersion = Select-String -InputObject $(Invoke-WebRequest "https://windows.php.net/download/").Content -Pattern "php-(7\.3\.\d+)-nts-Win32-(v.\d+)+-x86\.zip" | Foreach-Object { $_.Matches }
if ($null -eq $latestVersion) {
    $latestArchievedVersion = $(Select-String -InputObject $(Invoke-WebRequest "https://windows.php.net/downloads/releases/archives/").Content -Pattern "php-(7\.4\.\d+)-nts-Win32-(v.\d+)+-x86\.zip" -AllMatches | Foreach-Object { $_.Matches } | Get-Unique | Sort-Object { [System.Version]$_.Groups[1].Value })[-1]
    Write-Output "$($latestArchievedVersion.Groups[1].Value) $($latestArchievedVersion.Groups[2].Value)/archives/php"
}
else {
    Write-Output "$($latestVersion.Groups[1].Value) $($latestVersion.Groups[2].Value)/php"
}
