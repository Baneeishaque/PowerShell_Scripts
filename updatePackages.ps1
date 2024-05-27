$scriptDirectory = Split-Path -Parent $PSCommandPath

Write-Output 'Sqlyog Backup Jobs'
Write-Output '------------------------------'
Start-Process -FilePath 'C:\Program Files\SQLyog Trial\SJA.exe' -ArgumentList '"C:\Lab_Data\Account-Ledger-Server\db_backup_jobs\nomadller_hostinger_temp_Avita-Windows.xml" -l"C:\Users\dk\AppData\Roaming\SQLyog\sja.log" -s"C:\Users\dk\AppData\Roaming\SQLyog\sjasession.xml"' -Wait

Set-Location "$scriptDirectory"

Write-Output 'PowerShell Modules Backup'
Write-Output '------------------------------'
. "PowerShell_Modules_Scripts\CallSave-ModuleInfo.ps1"

Write-Output 'Optimize Scoop Cache'
Write-Output '------------------------------'
. "Scoop_Scripts\Optimize-ScoopCache.ps1"
Optimize-ScoopCache -dryRun $false

Write-Output 'Update Windows Store Apps'
Write-Output '------------------------------'
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod

Write-Output 'Winget Outdated Apps'
Write-Output '------------------------------'
winget upgrade --include-unknown --include-pinned --verbose-logs --disable-interactivity

Write-Output 'Scoop Outdated Apps'
Write-Output '------------------------------'
scoop update
scoop status

Write-Output 'Chocolatey Outdated Apps'
Write-Output '------------------------------'
# choco outdated --debug --verbose --trace --accept-license --confirm --prerelease
choco outdated --accept-license --confirm --prerelease

Write-Output 'Scoop Unused Buckets'
Write-Output '------------------------------'
sfsu unused-buckets

Write-Output 'After Chocolatey Update, Clean Chocolatey Cache'

Write-Output 'After Scoop Update Apps, Clean Scoop Apps'

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
