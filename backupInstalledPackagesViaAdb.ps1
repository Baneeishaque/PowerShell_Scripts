function Get-EmulatorInstanceName {
    param([string]$deviceInfo)

    $deviceToInstanceMap = @{
        'G011A' = 'Android 7 DIGI KGB Hajara Banee Gmail 1-2-3 MEmu'
        'A5010' = 'Android 7 DIGI KGB Ismail MEmu'
    }

    $instanceName = $deviceToInstanceMap[$deviceInfo]

    if ($instanceName) {
        return $instanceName
    }
    else {
        Write-Host "Emulator instance name not found for device: $deviceInfo"
        exit
    }
}

$deviceInfo = (adb devices -l | Select-String 'device product:').ToString() -replace '.*device product:(.+?)\s+model:.+?\s+device:.+?\s+transport_id:\d+', '$1'
$emulatorInstanceName = Get-EmulatorInstanceName -deviceInfo $deviceInfo

function Get-PackageInfo {
    param([string]$packageName)
    $packageInfo = adb shell dumpsys package $packageName
    $versionName = ($packageInfo | Select-String 'versionName=').ToString() -replace 'versionName=', '' -replace '\s+', ''
    $firstInstallTime = ($packageInfo | Select-String 'firstInstallTime=').ToString() -replace 'firstInstallTime=', '' -replace '^\s+|\s+$', '' -replace '\s+(\d+:\d+:\d+)', ' $1'
    $lastUpdateTime = ($packageInfo | Select-String 'lastUpdateTime=').ToString() -replace 'lastUpdateTime=', '' -replace '^\s+|\s+$', '' -replace '\s+(\d+:\d+:\d+)', ' $1'
    $installerPackageNameLine = $packageInfo | Select-String 'installerPackageName='
    $installerPackageName = if ($installerPackageNameLine) { $installerPackageNameLine.ToString() -replace 'installerPackageName=', '' -replace '\s+', '' } else { 'Not Available' }
    "$packageName,$versionName,$firstInstallTime,$lastUpdateTime,$installerPackageName"
}

$packageList = (adb shell pm list packages -3) -notmatch 'com.android.' | Sort-Object
$csvRows = foreach ($package in $packageList) { $packageName = $package -replace 'package:', '' -replace '\s+', ''; Get-PackageInfo -packageName $packageName }
$timestamp = Get-Date -Format 'MM-dd-yyyy HH-mm-ss'

$outputFileNameCurrentFolder = "${emulatorInstanceName} Packages ${timestamp}.csv"
$csvRows | Out-File -FilePath $outputFileNameCurrentFolder -Encoding UTF8
Write-Host "CSV file '$outputFileNameCurrentFolder' created in the current folder."

$outputFolder1 = 'C:\Lab_Data\configurations-private'
$outputFolder2 = "C:\Lab_Data\Memu-Virtual-Appliances\$emulatorInstanceName"
$outputFileNameFolder1 = Join-Path $outputFolder1 "${emulatorInstanceName} Packages.csv"
$outputFileNameFolder2 = Join-Path $outputFolder2 "${emulatorInstanceName} Packages.csv"

$csvRows | Out-File -FilePath $outputFileNameFolder1 -Encoding UTF8
$csvRows | Out-File -FilePath $outputFileNameFolder2 -Encoding UTF8

Write-Host "CSV files created in folders: '$outputFileNameFolder1', '$outputFileNameFolder2'"
