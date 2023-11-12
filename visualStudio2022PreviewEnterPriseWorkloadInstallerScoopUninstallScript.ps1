$app = 'visual-studio-2022-preview-enterprise-visualstudioextension-installer'
$matchResult = Select-String -InputObject $app -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-preview-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppFullVariant>-full)?(?<vSWorkloadAppRecommendedVariant>-recommended)?-installer)' | ForEach-Object -Process {$_.Matches}
$workloadInternalName = $matchResult.Groups[2].Value
$isIncludeRecommended = $matchResult.Groups[3].Success
$isIncludeOptional = $matchResult.Groups[4].Success

# $workloadInternalName
# $isIncludeRecommended
# $isIncludeOptional

$dir = scoop prefix $app
# $dir

# Start-Process -FilePath "$dir\vs_enterprise.exe" -ArgumentList "--remove=Microsoft.VisualStudio.Workload.$workloadInternalName$($isIncludeRecommended ? ";includeRecommended":$null)$($isIncludeOptional ? ";includeOptional":$null)", "--channelId=VisualStudio.17.Preview", "--productId=Microsoft.VisualStudio.Product.Enterprise", "--passive", "--norestart", "--wait" -Wait

$cmd = 'uninstall'
if ($cmd -ceq 'uninstall') {

    if ((scoop list | Select-String -Pattern '(?<visualStudioWorkloadApp>visual-studio-2022-preview-enterprise-(?<visualStudioWorkloadInternalName>[a-z]+)(?<vSWorkloadAppFullVariant>-full)?(?<vSWorkloadAppRecommendedVariant>-recommended)?-installer)' | ForEach-Object -Process { $_.Matches}) -is [System.Text.RegularExpressions.Group]) {

        Write-Output 'Welcome'
        # Start-Process -FilePath "$dir\vs_enterprise.exe" -ArgumentList "uninstall", "--channelId=VisualStudio.17.Preview", "--productId=Microsoft.VisualStudio.Product.Enterprise", "--passive", "--norestart", "--wait" -Wait
        # Start-Process -FilePath "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe" -ArgumentList "/uninstall" -Wait
        # Remove-Item "$([System.Environment]::GetFolderPath('commonstartmenu'))\Programs\Visual Studio Installer.lnk"
    }
}
else {
}
