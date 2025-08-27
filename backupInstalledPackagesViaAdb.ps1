#!pwsh
function Get-EmulatorInstanceName {
    param([string]$deviceInfo)

    $deviceToInstanceMap = @{
        'G011A'  = 'Android 7 DIGI KGB Hajara Banee Gmail 1-2-3 MEmu'
        'A5010'  = 'Android 7 DIGI KGB Ismail MEmu'
		'SM-G935FD' = 'Android 9 Banee Gmail 1-2 MEmu'
		'ASUS_Z01QD' = 'Android 9 MEmu Bing'
        'b0qxxx' = 'Android 11 BlueStacks App Player'
        'r0qxxx' = 'Android 11 Banee Gmail BlueStacks App Player'
    }

    $instanceName = $deviceToInstanceMap[$deviceInfo]

    if ($instanceName) {
        return $instanceName
    }
    else {
        return $deviceInfo
    }
}

$deviceInfos = (adb devices -l | Select-String 'device product:')

foreach ($deviceInfo in $deviceInfos) {

    $deviceId = ($deviceInfo -replace '(\w+)\s+device.*', '$1')
    $deviceInfo = $deviceInfo -replace '.*device product:(.+?)\s+model:.+?\s+device:.+?\s+transport_id:\d+', '$1'
    $emulatorInstanceName = Get-EmulatorInstanceName -deviceInfo $deviceInfo

    function Get-PackageInfo {
        param([string]$packageName)
        $packageInfo = adb -s $deviceId shell dumpsys package $packageName
        $versionName = ($packageInfo | Select-String 'versionName=').ToString() -replace 'versionName=', '' -replace '\s+', ''
        $firstInstallTime = ($packageInfo | Select-String 'firstInstallTime=').ToString() -replace 'firstInstallTime=', '' -replace '^\s+|\s+$', '' -replace '\s+(\d+:\d+:\d+)', ' $1'
        $lastUpdateTime = ($packageInfo | Select-String 'lastUpdateTime=').ToString() -replace 'lastUpdateTime=', '' -replace '^\s+|\s+$', '' -replace '\s+(\d+:\d+:\d+)', ' $1'
        $installerPackageNameLine = $packageInfo | Select-String 'installerPackageName='
        $installerPackageName = if ($installerPackageNameLine) { $installerPackageNameLine.ToString() -replace 'installerPackageName=', '' -replace '\s+', '' } else { 'Not Available' }
        "$packageName,$versionName,$firstInstallTime,$lastUpdateTime,$installerPackageName"
    }

    $packageList = (adb -s $deviceId shell pm list packages -3) -notmatch 'com.android.' | Sort-Object
    $csvRows = foreach ($package in $packageList) { $packageName = $package -replace 'package:', '' -replace '\s+', ''; Get-PackageInfo -packageName $packageName }
    $timestamp = Get-Date -Format 'MM-dd-yyyy HH-mm-ss'

    $outputFileNameCurrentFolder = "${emulatorInstanceName} Packages ${timestamp}.csv"
    $csvRows | Out-File -FilePath $outputFileNameCurrentFolder -Encoding UTF8
    Write-Host "CSV file '$outputFileNameCurrentFolder' created in the current folder."

    $outputFolder1 = 'C:\Lab_Data\configurations-private'
    $outputFileNameFolder1 = Join-Path $outputFolder1 "${emulatorInstanceName} Packages.csv"
    $csvRows | Out-File -FilePath $outputFileNameFolder1 -Encoding UTF8
    Write-Host "CSV file '$outputFileNameFolder1' created in folder '$outputFolder1'."

    if ($emulatorInstanceName -match 'MEmu') {
        $outputFolder2 = "C:\Lab_Data\Memu-Virtual-Appliances\$emulatorInstanceName"
        $outputFileNameFolder2 = Join-Path $outputFolder2 "${emulatorInstanceName} Packages.csv"
        $csvRows | Out-File -FilePath $outputFileNameFolder2 -Encoding UTF8
        Write-Host "CSV file '$outputFileNameFolder2' created in folder '$outputFolder2'."
    }
    elseif ($emulatorInstanceName -match 'BlueStacks') {
        $outputFolder2 = 'C:\Lab_Data\BlueStacks-Backups'
        $outputFileNameFolder2 = Join-Path $outputFolder2 "${emulatorInstanceName} Packages.csv"
        $csvRows | Out-File -FilePath $outputFileNameFolder2 -Encoding UTF8
        Write-Host "CSV file '$outputFileNameFolder2' created in folder '$outputFolder2'."
    }
}
