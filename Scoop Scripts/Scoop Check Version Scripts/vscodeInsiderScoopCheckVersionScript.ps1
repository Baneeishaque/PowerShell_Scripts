$releaseData = Invoke-WebRequest "https://update.code.visualstudio.com/api/update/win32-x64-archive/insider/latest" | ConvertFrom-Json
"$($releaseData.productVersion)-$($releaseData.timestamp)"
