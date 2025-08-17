<#
.SYNOPSIS
    Consolidates .vscode/extensions.json files from first-level directories into a single extensions.json file.

.DESCRIPTION
    This script traverses only first-level folders in the parent directory, checks if each folder 
    contains a .vscode/extensions.json file, reads and parses all found JSON files, concatenates 
    all extensions while removing duplicates, and creates a new consolidated extensions.json file 
    in the current folder's .vscode directory.

.PARAMETER SourcePath
    The path to search for first-level directories. Defaults to parent of current directory.

.PARAMETER OutputPath
    The path where the consolidated extensions.json should be created. Defaults to current directory.

.EXAMPLE
    .\Consolidate-VSCodeExtensions.ps1
    Consolidates extensions.json files from first-level directories in the parent directory.

.EXAMPLE
    .\Consolidate-VSCodeExtensions.ps1 -SourcePath "C:\Projects" -OutputPath "C:\Projects\MyRepo"
    Consolidates extensions.json files from C:\Projects first-level directories into MyRepo.

.NOTES
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+
    Creates .vscode directory if it doesn't exist
    Removes duplicates from arrays
    Uses Common-Utils.ps1 for reusable functions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = (Split-Path -Parent (Get-Location).Path),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path
)

# Import common utilities
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $scriptDir "Common-Utils.ps1")

# Main execution
try {
    Write-Message "=== VS Code Extensions Consolidator ===" "Magenta"
    Write-Message "Source Path: $SourcePath" "Gray"
    Write-Message "Output Path: $OutputPath" "Gray"
    Write-Message ""
    
    # Find all extensions.json files using utility function
    Write-Message "Searching for .vscode/extensions.json files in first-level directories..." "Cyan"
    Write-Message "Search path: $SourcePath" "Gray"
    
    $extensionsFiles = Find-FilesInFirstLevelDirectories -SearchPath $SourcePath -RelativeFilePath ".vscode/extensions.json"
    
    # Display found files
    foreach ($file in $extensionsFiles) {
        Write-Message "Found: $file" "Green"
    }
    
    if ($extensionsFiles.Count -eq 0) {
        Write-Message "No .vscode/extensions.json files found in first-level directories." "Yellow"
        exit 0
    }
    
    Write-Message "`nFound $($extensionsFiles.Count) extensions.json file(s)" "Green"
    
    # Read all JSON files
    Write-Message "Reading JSON files..." "Cyan"
    $jsonObjects = @()
    foreach ($file in $extensionsFiles) {
        $jsonData = Read-JsonFile -FilePath $file
        if ($null -ne $jsonData) {
            $jsonObjects += $jsonData
        }
    }
    
    if ($jsonObjects.Count -eq 0) {
        Write-Message "No valid JSON data found in files." "Yellow"
        exit 0
    }
    
    # Merge all JSON objects using utility function
    Write-Message "Consolidating extensions..." "Cyan"
    $consolidated = Merge-JsonObjects -JsonObjects $jsonObjects
    
    # Create output file
    $vscodeDir = Join-Path -Path $OutputPath -ChildPath ".vscode"
    $outputFile = Join-Path -Path $vscodeDir -ChildPath "extensions.json"
    
    # Create .vscode directory if needed
    if (New-DirectoryIfNotExists -Path $vscodeDir) {
        Write-Message "Created .vscode directory at: $vscodeDir" "Yellow"
    }
    
    # Write consolidated JSON file
    if (Write-JsonFile -Object $consolidated -FilePath $outputFile) {
        Write-Message "`nConsolidated extensions.json created at: $outputFile" "Green"
        
        # Display summary
        if ($consolidated.PSObject.Properties.Name -contains "recommendations") {
            Write-Message "Total recommendations: $($consolidated.recommendations.Count)" "Green"
        }
        if ($consolidated.PSObject.Properties.Name -contains "unwantedRecommendations") {
            Write-Message "Total unwanted recommendations: $($consolidated.unwantedRecommendations.Count)" "Green"
        }
        
        Write-Message "`n=== Consolidation complete! ===" "Magenta"
    } else {
        Write-Message "Failed to create consolidated extensions file." "Red"
        exit 1
    }
}
catch {
    Write-Message "An error occurred: $($_.Exception.Message)" "Red"
    exit 1
}
