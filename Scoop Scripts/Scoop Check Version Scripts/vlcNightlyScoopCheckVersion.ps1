$builds = 'win32', 'win64'
$urls =  @()
foreach ($build in $builds) {
    $base_url = 'https://artifacts.videolan.org/vlc/nightly-' + $build + '/'
    $page = Invoke-WebRequest $base_url -UseBasicParsing
    $full_version = $page.links | Where-Object href -match '\d+-\d+' | Select-Object -first 1 -expand href
    $dl_page = Invoke-WebRequest ($base_url + $full_version) -UseBasicParsing
    $scriptver = $full_version -split '-' | Select-Object -first 1
    $dl = $full_version + ($dl_page.links | Where-Object href -match '.7z' | Select-Object -first 1 -expand href)
    $urls += $dl
}
Write-Output ('version:' + $scriptver) ('urls:' + $urls)
