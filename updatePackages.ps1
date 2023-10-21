Write-Output 'Winget Outdated Apps'
Write-Output '------------------------------'
winget upgrade --include-unknown

Write-Output 'Scoop Outdated Apps'
Write-Output '------------------------------'
scoop update
scoop status

Write-Output 'Chocolatey Outdated Apps'
Write-Output '------------------------------'
choco outdated

Write-Output 'Update Windows Store Apps'
Write-Output '------------------------------'
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod

Write-Output 'After Scoop Update, Clean Scoop Cache'
Write-Output 'After Chocolatey Update, Clean Chocolatey Cache'

Write-Output 'Flutter master branch update'
Set-Location "$(scoop prefix fvm)\versions\master"
git pull
jabba use openjdk@11.0.16
Set-Location C:\Lab_Data\Account_Ledger_Windows_Flutter\account_ledger_lib_kotlin_native
.\compileMainCFile.ps1
fvm spawn master clean
fvm spawn master build windows --debug
fvm spawn master build windows
