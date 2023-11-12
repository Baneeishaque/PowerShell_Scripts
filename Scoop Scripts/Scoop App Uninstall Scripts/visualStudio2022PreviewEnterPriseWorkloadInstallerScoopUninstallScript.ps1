$bucket = 'versions-fork'
$app = 'visual-studio-2022-preview-enterprise-nativedesktop-recommended-installer'
$matchResult = Select-String -InputObject $app -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-preview-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppFullVariant>-full)?(?<vSWorkloadAppRecommendedVariant>-recommended)?-installer)' | ForEach-Object -Process { $_.Matches }
$workloadInternalName = $matchResult.Groups[2].Value
$isIncludeRecommended = $matchResult.Groups[3].Success
$isIncludeOptional = $matchResult.Groups[4].Success

# $workloadInternalName
# $isIncludeRecommended
# $isIncludeOptional

$dir = scoop prefix $app
# $dir

# Start-Process -FilePath "$dir\vs_enterprise.exe" -ArgumentList "--remove=Microsoft.VisualStudio.Workload.$workloadInternalName$($isIncludeRecommended ? ";includeRecommended":$null)$($isIncludeOptional ? ";includeOptional":$null)", "--channelId=VisualStudio.17.Preview", "--productId=Microsoft.VisualStudio.Product.Enterprise", "--passive", "--norestart", "--wait" -Wait

$cmd = 'update'

function Clear-VisualStudio {

    Write-Output 'Welcome'
    # Start-Process -FilePath "$dir\vs_enterprise.exe" -ArgumentList "uninstall", "--channelId=VisualStudio.17.Preview", "--productId=Microsoft.VisualStudio.Product.Enterprise", "--passive", "--norestart", "--wait" -Wait
    # Start-Process -FilePath "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe" -ArgumentList "/uninstall" -Wait
    # Remove-Item "$([System.Environment]::GetFolderPath('commonstartmenu'))\Programs\Visual Studio Installer.lnk"
}

$installedVisualStudioWorkloads = scoop list | Select-String -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-preview-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppFullVariant>-full)?(?<vSWorkloadAppRecommendedVariant>-recommended)?-installer)' | ForEach-Object -Process { $_.Matches }

if ($cmd -ceq 'uninstall') {

    if ($installedVisualStudioWorkloads -is [System.Text.RegularExpressions.Group]) {

        Clear-VisualStudio
    }
}
elseif ($cmd -ceq 'update') {

    if ($installedVisualStudioWorkloads -is [System.Text.RegularExpressions.Group]) {

        Clear-VisualStudio
    }
    else {

        $otherInstalledVisualStudioWorkloads = $installedVisualStudioWorkloads | Where-Object -Property Value -CNE $app
        # $otherInstalledVisualStudioWorkloads
        $otherInstalledVisualStudioWorkloads | ForEach-Object -Process { scoop uninstall $_.Value }
        Clear-VisualStudio
        $otherInstalledVisualStudioWorkloads | ForEach-Object -Process { scoop install "$bucket/$($_.Value)" }
    }
}
