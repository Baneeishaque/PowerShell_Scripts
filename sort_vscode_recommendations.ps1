[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, Position=0)]
    [string]$FilePath
)

if (-not $PSBoundParameters.ContainsKey('FilePath')) {
    [string]$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    [string]$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
    $FilePath = Join-Path -Path $projectRoot -ChildPath ".vscode/extensions.json"
    Write-Host "No file path provided. Defaulting to: $FilePath"
}

if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
    Write-Error "Error: File not found at '$FilePath'"
    exit 1
}

[System.IO.FileInfo]$fileInfo = Get-Item -Path $FilePath
if ($fileInfo.IsReadOnly) {
    Write-Error "Error: File at '$FilePath' is read-only."
    exit 1
}

try {
    [string]$fileContentRaw = Get-Content -Path $FilePath -Raw -ErrorAction Stop
} catch {
    Write-Error "Error: Cannot read file at '$FilePath'. Check permissions."
    Write-Error $_.Exception.Message
    exit 1
}

[string]$jsonContent = [System.Text.RegularExpressions.Regex]::Replace($fileContentRaw, '/\*.*?\*/', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
$jsonContent = [System.Text.RegularExpressions.Regex]::Replace($jsonContent, '//.*', '')

try {
    [psobject]$extensionsJson = $jsonContent | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Error: Invalid JSON in file '$FilePath' after stripping comments."
    Write-Error $_.Exception.Message
    exit 1
}

if ($null -ne $extensionsJson.recommendations) {
    [array]$originalRecommendations = @($extensionsJson.recommendations)
    [array]$sortedRecommendations = $originalRecommendations | Sort-Object

    if (-not (Compare-Object -ReferenceObject $originalRecommendations -DifferenceObject $sortedRecommendations -SyncWindow 0)) {
        Write-Host "Recommendations in '$FilePath' are already sorted. No changes made."
        exit 0
    }
    $extensionsJson.recommendations = $sortedRecommendations
} else {
    Write-Warning "Warning: No 'recommendations' property found in '$FilePath'."
    exit 0
}

[string]$outJson = $extensionsJson | ConvertTo-Json -Depth 100
$outJson = $outJson + [System.Environment]::NewLine

try {
    Set-Content -Path $FilePath -Value $outJson -Encoding UTF8 -ErrorAction Stop
    Write-Host "Successfully sorted recommendations in '$FilePath'"
} catch {
    Write-Error "Error: Could not write to file '$FilePath'."
    Write-Error $_.Exception.Message
    exit 1
}
