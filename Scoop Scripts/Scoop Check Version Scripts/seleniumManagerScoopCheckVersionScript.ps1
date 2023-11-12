$executable = "selenium-manager.exe"
Invoke-WebRequest -URI "https://github.com/SeleniumHQ/selenium/raw/trunk/common/manager/windows/$executable" -OutFile $executable
[array] $cmdOutput = Invoke-Expression ".\$executable --version"
Remove-Item $executable
$cmdOutput
