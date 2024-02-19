$dir = 'C:\Temp_Data\'
$url = 'https://jdownloader.org/jdownloader2'
$pageContent = Invoke-WebRequest -Uri $url
# $pageContent
# exit
$pattern = 'title="(.+)" >Download Installer \(x64'
$matchResult = $pageContent | Select-String -Pattern $pattern
# $matchResult.Matches.Groups[1]
# exit
$megaLink = if($matchResult.Matches) { $matchResult.Matches.Groups[1].Value }
$setupFilePath = Join-Path -Path $dir -ChildPath "setup.exe"
mega-get $megaLink $setupFilePath
# Start-Process -FilePath $setupFilePath -ArgumentList "-q" -Wait
# Remove-Item "$dir\setup.exe"
