Write-Output 'Flutter master branch update'
Set-Location "$(scoop prefix fvm)\versions\master"
git pull

Write-Output 'Buildign flutter sample apps'
Write-Output '------------------------------'
$tempLocation = 'C:\Flutter-Temp-Lab'
$tempAppName = 'my_app'
$tempModuleName = 'my_module'
fvm spawn master config --jdk-dir=$(jabba which openjdk@19.0.2)
New-Item -Path $tempLocation -ItemType Directory
Set-Location $tempLocation
fvm spawn master create $tempAppName
Set-Location $tempAppName
fvm spawn master build bundle
fvm spawn master build apk
fvm spawn master build appbundle
fvm spawn master build windows
fvm spawn master build web
fvm spawn master build bundle --debug
fvm spawn master build apk --debug
fvm spawn master build appbundle --debug
fvm spawn master build windows --debug
Set-Location ..
Remove-Item $tempAppName -Recurse
fvm spawn master create $tempModuleName --template=module
Set-Location $tempModuleName
fvm spawn master build aar
fvm spawn master build aar --debug
Set-Location ..
Remove-Item $tempModuleName -Recurse
Set-Location ..
Remove-Item $tempLocation -Recurse
Set-Location $PSScriptRoot
