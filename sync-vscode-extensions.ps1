#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronizes VS Code extensions between .gitpod.yml and .vscode/extensions.json files.

.DESCRIPTION
    This script reads VS Code extension recommendations from both .gitpod.yml and .vscode/extensions.json
    files and synchronizes them, ensuring both files contain the same set of extensions.
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.

.PARAMETER FolderPath
    The path to the folder containing .gitpod.yml and .vscode/extensions.json files.

.PARAMETER Quiet
    Run silently without output.

.EXAMPLE
    sync-vscode-extensions.ps1 "C:\MyProject"
    Synchronizes extensions for the project in C:\MyProject.

.EXAMPLE
    sync-vscode-extensions.ps1 "." -Quiet
    Synchronizes extensions for the current directory quietly.

.NOTES
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.
    Requires jq command-line JSON processor to be installed.
    Reuses common utility functions via dot-sourcing for DRY principle.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, HelpMessage="The path to the folder containing .gitpod.yml and .vscode/extensions.json")]
    [string]$FolderPath,
    
    [Parameter(HelpMessage="Run silently without output")]
    [switch]$Quiet
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import common utilities via dot-sourcing (DRY principle)
$scriptDirectory = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDirectory "Common-Utils.ps1")

# Main execution
try {
    Write-Message "🔄 VS Code Extensions Synchronizer" "Green" -Quiet:$Quiet
    Write-Message "==================================" "Green" -Quiet:$Quiet
    
    # Check if jq command is available using reusable function
    if (-not (Test-CommandExists "jq")) {
        Write-Message "❌ jq command not found. Please install jq first." "Red" -Quiet:$Quiet
        Write-Message "💡 Install with: brew install jq" "Cyan" -Quiet:$Quiet
        exit 1
    }
    
    [string]$resolvedFolderPath = (Resolve-Path -Path $FolderPath).Path
    [string]$gitpodYmlPath = Join-Path -Path $resolvedFolderPath -ChildPath ".gitpod.yml"
    [string]$extensionsJsonPath = Join-Path -Path $resolvedFolderPath -ChildPath ".vscode/extensions.json"
    
    # Check if required files exist
    if (-not ([System.IO.File]::Exists($gitpodYmlPath))) { 
        Write-Message "❌ File not found: $gitpodYmlPath" "Red" -Quiet:$Quiet
        exit 1 
    }
    if (-not ([System.IO.File]::Exists($extensionsJsonPath))) { 
        Write-Message "❌ File not found: $extensionsJsonPath" "Red" -Quiet:$Quiet
        exit 1 
    }

    Write-Message "🔍 Reading extension recommendations..." "Cyan" -Quiet:$Quiet
    
    [string[]]$jsonRecommendations = @()
    try {
        $jsonRecommendations = [System.IO.File]::ReadAllText($extensionsJsonPath) | jq -r '.recommendations[]'
    } catch {
        Write-Message "❌ Error reading or parsing '$extensionsJsonPath' with jq. Ensure it is valid JSON." "Red" -Quiet:$Quiet
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
    Write-Message "✅ Successfully synchronized extensions to '$gitpodYmlPath'" "Green" -Quiet:$Quiet
} else {
    Write-Message "⚠️ Warning: Could not find 'vscode.extensions' section in '$gitpodYmlPath'." "Yellow" -Quiet:$Quiet
}

Write-Message "💾 Writing JSON extensions file..." "Cyan" -Quiet:$Quiet
[psobject]$jsonForJq = @{ recommendations = $allExtensions }
[string]$newJsonContent = $jsonForJq | ConvertTo-Json -Depth 100 | jq --indent 2 '.'
[System.IO.File]::WriteAllText($extensionsJsonPath, ($newJsonContent + [System.Environment]::NewLine))
Write-Message "✅ Successfully synchronized extensions to '$extensionsJsonPath'" "Green" -Quiet:$Quiet

Write-Message "🎉 Extension synchronization completed successfully!" "Green" -Quiet:$Quiet

}
catch {
    Write-Message "❌ Synchronization failed: $($_.Exception.Message)" "Red" -Quiet:$Quiet
    exit 1
}
