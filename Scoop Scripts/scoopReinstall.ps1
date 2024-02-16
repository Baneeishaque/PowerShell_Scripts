$i = 0
Get-Content .\scoop_pacakges.txt | ForEach-Object {
    if (-NOT [string]::IsNullOrWhiteSpace($_)) {
        # Write-Output $i
        if ($i -ge 3) {
            # Write-Output $i

            # Write-Output $_

            $appData = ""
            $isStringStart = $false
            $k = 0
            $appDetails = 0..4
            [char[]] $_ | ForEach-Object {
                # Write-Output $_

                if (-NOT [string]::IsNullOrWhiteSpace(($_))) {
                    # Write-Output $_
                    $isStringStart = $true
                    $appData = $appData + $_
                }
                else {
                    if ($isStringStart) {
                        # Write-Output $appData
                        # Write-Output $k
                        $appDetails[$k] = $appData
                        # Write-Output $appDetails
                        $k++
                        $isStringStart = $false
                        $appData = ""
                    }
                }
            }
            # Write-Output $appDetails
            if ($appDetails[2] -eq "<auto-generated>") {
                "scoop install $($appDetails[0])@$($appDetails[1])" | Out-File -Append -FilePath scoopReinstallHelper.ps1
                # Start-Process "$HOME\scoop\apps\scoop\current\bin\scoop.ps1 install $($appDetails[0])@$($appDetails[1])"
            }
            else {
                "scoop install $($appDetails[2])/$($appDetails[0])" | Out-File -Append -FilePath scoopReinstallHelper.ps1
                # Start-Process "$HOME\scoop\apps\scoop\current\bin\scoop.ps1 install $($appDetails[2])/$($appDetails[0])"
            }
        }
    }
    $i++
}