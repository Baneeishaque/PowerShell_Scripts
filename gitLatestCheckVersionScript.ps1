# # $latest = Select-String -InputObject $(Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/").Content -Pattern 'tag/v(?<version>[\d.]+)(?<candidate>(-rc\d\d?)?).windows.(?<patch>\d\d?).+Git f' -AllMatches | ForEach-Object { $_.Matches }
# $latest = Select-String -InputObject $(Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases?page=2").Content -Pattern 'tag/v(?<version>[\d.]+)(?<candidate>(-rc\d\d?)?).windows.(?<patch>\d\d?).+Git f' -AllMatches | ForEach-Object { $_.Matches }
# # $latest
# $latest | ForEach-Object {

#     # if ($_.Groups[4].Value -gt 1){

#     #     Write-Output "$($_.Groups[2].Value).$($_.Groups[4].Value)$($_.Groups[3].Value)"

#     # }else{

#     #     Write-Output "$($_.Groups[2].Value)$($_.Groups[3].Value)"
#     # }
#     Write-Output "$($_.Groups[2].Value).$($_.Groups[4].Value)$($_.Groups[3].Value)"
# }

$latest = Select-String -InputObject $(Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/').Content -Pattern 'tag/v(?<version>[\d.]+)(?<candidate>(-rc\d\d?)?).windows.(?<patch>\d\d?).+Git f'
# $latest.Matches.Groups
# if ($latest.Matches.Groups[4].Value -gt 1) {

#     Write-Output "$($latest.Matches.Groups[2].Value).$($latest.Matches.Groups[4].Value)$($latest.Matches.Groups[3].Value)"

# }
# else {

#     Write-Output "$($latest.Matches.Groups[2].Value)$($latest.Matches.Groups[3].Value)"
# }
Write-Output "$($latest.Matches.Groups[2].Value).$($latest.Matches.Groups[4].Value)$($latest.Matches.Groups[3].Value)"
