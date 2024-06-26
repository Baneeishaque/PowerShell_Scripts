function Clear-VisualStudio {

    Write-Output "Start-Process -FilePath `"$dir\vs_enterprise.exe`" -ArgumentList `"uninstall`", `"--channelId=VisualStudio.17.Preview`", `"--productId=Microsoft.VisualStudio.Product.Enterprise`", `"--passive`", `"--norestart`", `"--wait`" -Wait"

    $installedVisualStudioWorkloads = & "$(scoop prefix scoop)\\bin\\scoop.ps1" list | Select-String -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppRecommendedVariant>-recommended)?(?<vSWorkloadAppFullVariant>-full)?-installer)' | ForEach-Object -Process { $_.Matches }
    if ($installedVisualStudioWorkloads.Count -eq 0){

        Write-Output "Start-Process -FilePath `"${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe`" -ArgumentList `"/uninstall`" -Wait"
        Write-Output "Remove-Item `"$([System.Environment]::GetFolderPath('commonstartmenu'))\Programs\Visual Studio Installer.lnk`""
    }
}

$bucket = 'versions-fork'
$app = 'visual-studio-2022-preview-enterprise-nativedesktop-recommended-installer'

$matchResult = Select-String -InputObject $app -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-preview-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppRecommendedVariant>-recommended)?(?<vSWorkloadAppFullVariant>-full)?-installer)' | ForEach-Object -Process { $_.Matches }
# $matchResult.Groups

$workloadInternalName = $matchResult.Groups[2].Value
$isIncludeRecommended = $matchResult.Groups[3].Success
$isIncludeOptional = $matchResult.Groups[4].Success

Write-Output "workloadInternalName: $workloadInternalName"
Write-Output "isIncludeRecommended: $isIncludeRecommended"
Write-Output "isIncludeOptional: $isIncludeOptional"

$dir = scoop prefix $app
Write-Output "dir: $dir"

Write-Output "Start-Process -FilePath `"$dir\vs_enterprise.exe`" -ArgumentList `"--remove=Microsoft.VisualStudio.Workload.$workloadInternalName$($isIncludeRecommended ? ";includeRecommended":$null)$($isIncludeOptional ? ";includeOptional":$null)`", `"--channelId=VisualStudio.17.Preview`", `"--productId=Microsoft.VisualStudio.Product.Enterprise`", `"--passive`", `"--norestart`", `"--wait`" -Wait"

$cmd = 'update'

$installedVisualStudioPreviewWorkloads = & "$(scoop prefix scoop)\bin\scoop.ps1" list | Select-String -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-preview-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppRecommendedVariant>-recommended)?(?<vSWorkloadAppFullVariant>-full)?-installer)' | ForEach-Object -Process { $_.Matches }
Write-Output "installedVisualStudioPreviewWorkloads: $installedVisualStudioPreviewWorkloads"
Write-Output "installedVisualStudioPreviewWorkloads Type: $($installedVisualStudioPreviewWorkloads.GetType())"

if ($cmd -ceq 'uninstall') {

    if ($installedVisualStudioPreviewWorkloads -is [System.Text.RegularExpressions.Group]) {

        Clear-VisualStudio
    }
}
elseif ($cmd -ceq 'update') {

    if ($installedVisualStudioPreviewWorkloads -is [System.Text.RegularExpressions.Group]) {

        Clear-VisualStudio
    }
    else {

        $otherInstalledVisualStudioWorkloads = $installedVisualStudioPreviewWorkloads | Where-Object -Property Value -CNE $app
        Write-Output "otherInstalledVisualStudioWorkloads: $otherInstalledVisualStudioWorkloads"
        $otherInstalledVisualStudioWorkloads | ForEach-Object -Process { Write-Output "scoop uninstall $($_.Value)" }
        Clear-VisualStudio
        $isShowManifestEnabled = scoop config show_manifest
        Write-Output "isShowManifestEnabled: $isShowManifestEnabled"
        if ($isShowManifestEnabled){
            scoop config show_manifest $false
        }
        $otherInstalledVisualStudioWorkloads | ForEach-Object -Process { Write-Output "scoop install `"$bucket/$($_.Value)`"" }
        if ($isShowManifestEnabled){
            scoop config show_manifest $true
        }
    }
}
