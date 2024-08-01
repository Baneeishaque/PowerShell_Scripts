$osVersion = Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion'
Write-Output "$($osVersion.CurrentMajorVersionNumber).$($osVersion.CurrentMinorVersionNumber).$($osVersion.CurrentBuildNumber).$($osVersion.UBR)"
