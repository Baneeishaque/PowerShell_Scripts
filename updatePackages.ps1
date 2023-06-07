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
Set-Location C:\Lab_Data\Account_Ledger_Windows_Flutter
fvm flutter build --debug windows
