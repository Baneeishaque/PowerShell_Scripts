$latest = Select-String -InputObject $(Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/').Content -Pattern 'tag/v(?<version>[\d.]+)(?<candidate>(-rc\d\d?)?).windows.(?<patch>\d\d?).+Git f' -AllMatches | ForEach-Object -Process { $_.Matches }
# $latest = Select-String -InputObject $(Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/').Content -Pattern 'tag/v(?<version>[\d.]+)(?<candidate>(-rc\d\d?)?).windows.(?<patch>\d\d?).+Git f' | ForEach-Object -Process { $_.Matches }

foreach ($lat in $latest) {

    $versionText = "$($lat.Groups[2].Value).$($lat.Groups[4].Value)$($lat.Groups[3].Value)"
    $matchResult = Select-String -InputObject $versionText -Pattern '(?<version>[\d.]+(?<candidate>-rc\d\d?)?)'
    $fileVersionSuffix = $matchResult.Matches.Groups[2].Value -eq '' ? ($lat.Groups[4].Value -eq 1 ? '': ".$($lat.Groups[4].Value)") : $matchResult.Matches.Groups[2].Value
    $versionTextWithSuffix = "$($lat.Groups[2].Value).$($lat.Groups[4].Value)$($lat.Groups[3].Value)-suffix$fileVersionSuffix"
    $matchResultWithSuffix = Select-String -InputObject $versionTextWithSuffix -Pattern '(?<version>[\d.]+(?<candidate>-rc\d\d?)?)-suffix(?<suffix>.+)?'
    # $matchResultWithSuffix.Matches.Groups

    [System.Version]$version = "$($lat.Groups[2].Value).$($lat.Groups[4].Value)"
    $version

    wget --spider "https://github.com/git-for-windows/git/releases/download/v$($version.Major).$($version.Minor).$($version.Build)$($matchResult.Matches.Groups[2].Value).windows.$($version.Revision)/PortableGit-$($version.Major).$($version.Minor).$($version.Build)$($matchResultWithSuffix.Matches.Groups[3].Value)-32-bit.7z.exe"

    $hash = Select-String -InputObject $(Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/tag/v$($version.Major).$($version.Minor).$($version.Build)$($matchResult.Matches.Groups[2].Value).windows.$($version.Revision)").Content -Pattern "<td>PortableGit-$($version.Major).$($version.Minor).$($version.Build)$($matchResultWithSuffix.Matches.Groups[3].Value)-32-bit.7z.exe</td>\s*<td>(?<hash>.+)</td>"
    $hash.Matches.Groups[1].Value

    Write-Output '-----------------------------'
}
