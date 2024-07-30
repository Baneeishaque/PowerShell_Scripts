$betaVersion = [System.Version]$(Select-String -InputObject $(Invoke-WebRequest -Uri "https://telegram.org/dl/desktop/win64_portable?beta=1").BaseResponse.RequestMessage.RequestUri.AbsoluteUri -Pattern 'tportable-x64\.(.+)\.beta.zip').Matches.Groups[1].Value
# $betaVersion

$stableVersion = [System.Version]$(Select-String -InputObject $(Invoke-WebRequest -Uri "https://telegram.org/dl/desktop/win64_portable").BaseResponse.RequestMessage.RequestUri.AbsoluteUri -Pattern 'tportable-x64\.(.+)\.zip').Matches.Groups[1].Value
# $stableVersion

if($betaVersion -gt $stableVersion){
    Write-Output "$betaVersion .beta"
}else{
    Write-Output "$stableVersion"
}
