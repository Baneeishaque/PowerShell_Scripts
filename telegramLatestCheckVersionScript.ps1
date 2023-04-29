# $(Invoke-WebRequest -Uri "https://github.com/telegramdesktop/tdesktop/releases/").Content -match 'tag/v([\d.]+).+\s.+">(.+)<'
# $Matches

$latest = Select-String -InputObject $(Invoke-WebRequest -Uri "https://github.com/telegramdesktop/tdesktop/releases/").Content -Pattern 'tag/v([\d.]+).+\s.+">(.+)<'
if($latest.Matches.Groups[2].Value -ceq 'Pre-release'){
    $betaOrStable = '.beta'
}
else{
    $betaOrStable = ''
}
Write-Output "$($latest.Matches.Groups[1].Value)$betaOrStable"
