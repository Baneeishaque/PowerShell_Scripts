# $scriptver = ''
$base_url = 'https://artifacts.videolan.org/vlc/nightly-win64-ucrt-llvm/'
# Write-Output ($base_url)
$page = Invoke-WebRequest $base_url -UseBasicParsing
# Write-Output ($page)
# Write-Output ($page.links)
# Write-Output ($page.links | Where-Object href -match '\d\d\d\d\d\d\d\d-\d+')
# Write-Output ($page.links | Where-Object href -match '\d\d\d\d\d\d\d\d-\d+' | Select-Object -first 1 -expand href)
$full_version = $page.links | Where-Object href -match '\d\d\d\d\d\d\d\d-\d+' | Select-Object -first 1 -expand href
# Write-Output ($full_version)
$dl_page = Invoke-WebRequest ($base_url + $full_version) -UseBasicParsing
# Write-Output ($dl_page)
# Write-Output ($dl_page.links)
# Write-Output ($dl_page.links | Where-Object href -match '.7z')
# Write-Output ($dl_page.links | Where-Object href -match '.7z' | Select-Object -first 1 -expand href)
# $scriptver = $full_version -split '-' | Select-Object -first 1
$dl = $full_version + ($dl_page.links | Where-Object href -match '.7z' | Select-Object -first 1 -expand href)
# Write-Output ('version:' + $scriptver) ('url:' + $dl)
Write-Output $dl
