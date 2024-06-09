function Get-FileHash($url)
{
    return (Get-FileHash -InputStream (([System.Net.WebClient]::new()).OpenRead($url)) -Algorithm SHA256).Hash.ToLower()
}

function New-Manifests($latestVersion, $fileHash, $varient)
{
    $( Select-String -InputObject $( Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MicrosoftDocs/visualstudio-docs/main/docs/install/includes/vs-2022/workload-component-id-vs-enterprise.md" ).Content -Pattern "## (.+)\s\s\*\*ID:\*\* Microsoft\.VisualStudio\.Workload\.(.+)\s\s\*\*Description:\*\* (.+)" -AllMatches | ForEach-Object { $_.Matches } ) | ForEach-Object {

        # Write-Output $_.Groups[1].Value $_.Groups[2].Value $_.Groups[3].Value

        # Write-Output "visual-studio-2022-preview-enterprise-$($_.Groups[2].Value.ToLower())-installer.json"
        # Write-Output "visual-studio-2022-preview-enterprise-$($_.Groups[2].Value.ToLower())-recommended-installer.json"
        # Write-Output "visual-studio-2022-preview-enterprise-$($_.Groups[2].Value.ToLower())-full-installer.json"

        $destinationPrefix = "Scoop Manifests\visual-studio-2022$varient-enterprise-$($_.Groups[2].Value.ToLower() )-"
        $destinationSuffix = "installer.json"
        $destination = "$destinationPrefix$destinationSuffix"

        New-Item -ItemType File -Path $destination -Force
        Copy-Item "visual-studio-2022$varient-enterprise-workload-installer.json" -Destination $destination

        ((Get-Content -path $destination -Raw) -replace '{latestVersion}', $latestVersion) | Set-Content -Path $destination
        ((Get-Content -path $destination -Raw) -replace '{fileHash}', $fileHash) | Set-Content -Path $destination

        ((Get-Content -path $destination -Raw) -replace '{workloadFormalName}',$_.Groups[1].Value.ToLower()) | Set-Content -Path $destination
        ((Get-Content -path $destination -Raw) -replace '{workloadDescription}',$_.Groups[3].Value.ToLower()) | Set-Content -Path $destination

        ((Get-Content -path $destination -Raw) -replace '{workloadInternalName}', "$($_.Groups[2].Value.ToLower() );includeRecommended") | Set-Content -Path "$( $destinationPrefix )recommended-$( $destinationSuffix )"
        ((Get-Content -path $destination -Raw) -replace '{workloadInternalName}', "$($_.Groups[2].Value.ToLower() );includeRecommended;includeOptional") | Set-Content -Path "$( $destinationPrefix )full-$( $destinationSuffix )"
        ((Get-Content -path $destination -Raw) -replace '{workloadInternalName}',$_.Groups[2].Value.ToLower()) | Set-Content -Path $destination
    }
}

function Update-ScoopManifests()
{
    & "$( scoop prefix scoop )\bin\checkver.ps1" -Dir "Scoop Manifests" -Update -Force
}

# Generate manifests for Visual Studio
$latestVersion = $( Select-String -InputObject $( Invoke-WebRequest -Uri 'https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-notes' ).Content -Pattern '>Visual Studio 2022 version ([\d.]+)<' ).Matches.Groups[1].Value
$fileHash = Get-FileHash -url 'https://aka.ms/vs/17/release/vs_enterprise.exe'
New-Manifests -latestVersion $latestVersion -fileHash $fileHash -varient ""

# Generate manifests for Visual Studio Preview
$latestVersion = Select-String -InputObject $( Invoke-WebRequest -Uri 'https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-notes-preview' ).Content -Pattern 'Visual Studio 2022 version ((?<major>[\d.]+) Preview (?<minor>\d\d?))' | ForEach-Object -Process { "$( $_.Matches.Groups[2] ).$( $_.Matches.Groups[3] )" }
$fileHash = Get-FileHash -url 'https://aka.ms/vs/17/pre/vs_enterprise.exe'
New-Manifests -latestVersion $latestVersion -fileHash $fileHash -varient "-preview"

Update-ScoopManifests
