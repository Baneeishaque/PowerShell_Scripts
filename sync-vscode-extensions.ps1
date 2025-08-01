[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FolderPath
)

$ErrorActionPreference = "Stop"

[string]$resolvedFolderPath = (Resolve-Path -Path $FolderPath).Path
[string]$gitpodYmlPath = Join-Path -Path $resolvedFolderPath -ChildPath ".gitpod.yml"
[string]$extensionsJsonPath = Join-Path -Path $resolvedFolderPath -ChildPath ".vscode/extensions.json"

if (-not ([System.IO.File]::Exists($gitpodYmlPath))) { Write-Error "File not found: $gitpodYmlPath"; exit 1 }
if (-not ([System.IO.File]::Exists($extensionsJsonPath))) { Write-Error "File not found: $extensionsJsonPath"; exit 1 }
if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { Write-Error "jq not found. Please install it."; exit 1 }

[string[]]$jsonRecommendations = @()
try {
    $jsonRecommendations = [System.IO.File]::ReadAllText($extensionsJsonPath) | jq -r '.recommendations[]'
} catch {
    Write-Error "Error reading or parsing '$extensionsJsonPath' with jq. Ensure it is valid JSON."
    exit 1
}

[string[]]$gitpodYmlLines = [System.IO.File]::ReadAllLines($gitpodYmlPath)
[System.Collections.Generic.HashSet[string]]$yamlExtensions = New-Object System.Collections.Generic.HashSet[string]
[System.Collections.Generic.HashSet[string]]$commentedExtensions = New-Object System.Collections.Generic.HashSet[string]
[int]$extensionsLineIndex = -1
[string]$itemIndentation = ""
[int]$extensionsStartIndex = -1
[int]$extensionsEndIndex = -1

for ([int]$i = 0; $i -lt $gitpodYmlLines.Length; $i++) {
    if ($gitpodYmlLines[$i] -match "^(\s*)extensions:") {
        $extensionsLineIndex = $i
        $itemIndentation = $matches[1] + "  "
        $extensionsStartIndex = $i + 1
        break
    }
}

if ($extensionsLineIndex -ne -1) {
    $extensionsEndIndex = $extensionsLineIndex
    for ([int]$i = $extensionsStartIndex; $i -lt $gitpodYmlLines.Length; $i++) {
        if ($gitpodYmlLines[$i].Trim() -eq "" -or ($gitpodYmlLines[$i] -notmatch "^$itemIndentation")) {
            $extensionsEndIndex = $i - 1
            break
        }
        $extensionsEndIndex = $i
    }

    if ($extensionsStartIndex -le $extensionsEndIndex) {
        for ([int]$i = $extensionsStartIndex; $i -le $extensionsEndIndex; $i++) {
            [string]$line = $gitpodYmlLines[$i]
            [System.Text.RegularExpressions.Match]$match = [System.Text.RegularExpressions.Regex]::Match($line, "^\s*-\s*(#\s*)?([\w\d.-]+)")
            if ($match.Success) {
                [string]$extName = $match.Groups[2].Value
                $yamlExtensions.Add($extName) | Out-Null
                if ($match.Groups[1].Length -gt 0) {
                    $commentedExtensions.Add($extName) | Out-Null
                }
            }
        }
    }
}

[string[]]$allExtensions = ($jsonRecommendations + $yamlExtensions) | Sort-Object -Unique

if ($extensionsLineIndex -ne -1) {
    [System.Collections.Generic.List[string]]$newExtensionLines = New-Object System.Collections.Generic.List[string]
    foreach ($ext in $allExtensions) {
        [string]$line
        if ($commentedExtensions.Contains($ext)) {
            $line = "$($itemIndentation)- # $($ext)"
        } else {
            $line = "$($itemIndentation)- $($ext)"
        }
        $newExtensionLines.Add($line)
    }

    [System.Collections.Generic.List[string]]$newGitpodYmlContent = New-Object System.Collections.Generic.List[string]
    if ($extensionsLineIndex > 0) {
        $newGitpodYmlContent.AddRange([string[]]$gitpodYmlLines[0..($extensionsLineIndex-1)])
    }
    $newGitpodYmlContent.Add($gitpodYmlLines[$extensionsLineIndex])
    $newGitpodYmlContent.AddRange($newExtensionLines)
    if ($extensionsEndIndex -lt ($gitpodYmlLines.Length - 1)) {
        $newGitpodYmlContent.AddRange([string[]]$gitpodYmlLines[($extensionsEndIndex + 1)..($gitpodYmlLines.Length - 1)])
    }

    [System.IO.File]::WriteAllLines($gitpodYmlPath, $newGitpodYmlContent)
    Write-Host "Successfully synchronized extensions to '$gitpodYmlPath'"
} else {
    Write-Warning "Warning: Could not find 'vscode.extensions' section in '$gitpodYmlPath'."
}

[psobject]$jsonForJq = @{ recommendations = $allExtensions }
[string]$newJsonContent = $jsonForJq | ConvertTo-Json -Depth 100 | jq --indent 2 '.'
[System.IO.File]::WriteAllText($extensionsJsonPath, ($newJsonContent + [System.Environment]::NewLine))
Write-Host "Successfully synchronized extensions to '$extensionsJsonPath'"
