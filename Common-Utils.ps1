#Requires -Version 5.1
<#
.SYNOPSIS
    Common PowerShell utilities script with reusable functions for dot-sourcing.

.DESCRIPTION
    This script contains common utility functions that can be reused across multiple PowerShell scripts.
    Functions are sourced from existing scripts following DRY principles.
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.
    
    Usage: . "Common-Utils.ps1"

.NOTES
    Functions extracted from existing scripts for reusability:
    - Write-Message: from sync-warp-rules.ps1
    - Test-GitRepository: from sync-warp-rules.ps1  
    - Test-GitClean: from sync-warp-rules.ps1
    - Test-FileClean: from sync-warp-rules.ps1
    - Test-CommandExists: common pattern from multiple scripts
    - Find-FilesInFirstLevelDirectories: for first-level directory traversal and file search
    - Read-JsonFile: for JSON file reading with error handling
    - Write-JsonFile: for JSON file writing with proper formatting
    - New-DirectoryIfNotExists: for directory creation
    - Merge-JsonObjects: for merging multiple JSON objects with array deduplication
    - Get-GitSubmodulePaths: for getting git submodule directories
    - Get-FilesArray: for listing files in a directory (recursive or not)
    - Resolve-FileNameConflicts: for resolving file name conflicts with suffixes (_2, _3, etc.)
#>

# Write message with color support (cross-platform PowerShell compatibility)
function Write-Message {
    <#
    .SYNOPSIS
        Writes a message with optional color formatting.
    
    .DESCRIPTION
        Provides consistent message output with color support across Windows PowerShell 5.1+ and PowerShell Core 7+.
        Extracted from sync-warp-rules.ps1 for reusability.
    
    .PARAMETER Message
        The message to display.
    
    .PARAMETER Color
        The foreground color for the message (default: White).
    
    .PARAMETER Quiet
        Suppress output if specified.
    
    .EXAMPLE
        Write-Message "Success!" "Green"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White",
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )
    
    if (-not $Quiet) {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Host $Message -ForegroundColor $Color
        } else {
            # Windows PowerShell compatibility
            Write-Host $Message
        }
    }
}

# Test if a directory is a Git repository
function Test-GitRepository {
    <#
    .SYNOPSIS
        Tests if a directory contains a Git repository.
    
    .DESCRIPTION
        Checks for the existence of a .git directory to determine if the path is a Git repository.
        Extracted from sync-warp-rules.ps1 for reusability.
    
    .PARAMETER Path
        The path to test.
    
    .EXAMPLE
        Test-GitRepository "C:\MyRepo"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    return Test-Path (Join-Path $Path ".git")
}

# Test if Git repository has uncommitted changes
function Test-GitClean {
    <#
    .SYNOPSIS
        Tests if a Git repository has a clean working directory.
    
    .DESCRIPTION
        Checks if there are any uncommitted changes in the Git repository.
        Extracted from sync-warp-rules.ps1 for reusability.
    
    .PARAMETER Path
        The path to the Git repository.
    
    .EXAMPLE
        Test-GitClean "C:\MyRepo"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        $originalLocation = Get-Location
        Set-Location $Path
        $status = git status --porcelain 2>$null
        return [string]::IsNullOrEmpty($status)
    }
    catch {
        return $false
    }
    finally {
        Set-Location $originalLocation
    }
}

# Test if a specific file is clean in Git
function Test-FileClean {
    <#
    .SYNOPSIS
        Tests if a specific file has uncommitted changes in Git.
    
    .DESCRIPTION
        Checks if a specific file has uncommitted changes in the Git repository.
        Extracted from sync-warp-rules.ps1 for reusability.
    
    .PARAMETER FilePath
        The path to the file to check.
    
    .EXAMPLE
        Test-FileClean "C:\MyRepo\README.md"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $originalLocation = Get-Location
        Set-Location (Split-Path $FilePath -Parent)
        $fileName = Split-Path $FilePath -Leaf
        $status = git status --porcelain $fileName 2>$null
        return [string]::IsNullOrEmpty($status)
    }
    catch {
        return $true  # If git fails, assume file is clean
    }
    finally {
        Set-Location $originalLocation
    }
}

# Test if a command exists in PATH
function Test-CommandExists {
    <#
    .SYNOPSIS
        Tests if a command exists and is accessible in PATH.
    
    .DESCRIPTION
        Common pattern used across multiple scripts to check for command availability.
    
    .PARAMETER CommandName
        The name of the command to check.
    
    .EXAMPLE
        Test-CommandExists "brew"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )
    
    return $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
}

# Find files in first-level directories
function Find-FilesInFirstLevelDirectories {
    <#
    .SYNOPSIS
        Searches for files in first-level directories only.
    
    .DESCRIPTION
        Traverses only first-level folders and searches for specific files.
        Common pattern for finding configuration files across project directories.
    
    .PARAMETER SearchPath
        The parent directory to search in.
    
    .PARAMETER RelativeFilePath
        The relative path to the file to search for (e.g., ".vscode/extensions.json").
    
    .PARAMETER ExcludeHidden
        Exclude directories that start with a dot (default: $true).
    
    .EXAMPLE
        Find-FilesInFirstLevelDirectories -SearchPath "/Users/dk/Lab_Data" -RelativeFilePath ".vscode/extensions.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchPath,
        
        [Parameter(Mandatory = $true)]
        [string]$RelativeFilePath,
        
        [Parameter(Mandatory = $false)]
        [bool]$ExcludeHidden = $true
    )
    
    $foundFiles = @()
    
    if (!(Test-Path -Path $SearchPath -PathType Container)) {
        Write-Warning "Search path does not exist: $SearchPath"
        return $foundFiles
    }
    
    $firstLevelDirs = Get-ChildItem -Path $SearchPath -Directory
    if ($ExcludeHidden) {
        $firstLevelDirs = $firstLevelDirs | Where-Object { !$_.Name.StartsWith('.') }
    }
    
    foreach ($dir in $firstLevelDirs) {
        $filePath = Join-Path -Path $dir.FullName -ChildPath $RelativeFilePath
        if (Test-Path -Path $filePath -PathType Leaf) {
            $foundFiles += $filePath
        }
    }
    
    return $foundFiles
}

# Read JSON file with error handling
function Read-JsonFile {
    <#
    .SYNOPSIS
        Reads and parses a JSON file with error handling.
    
    .DESCRIPTION
        Common pattern for reading JSON files with consistent error handling.
    
    .PARAMETER FilePath
        The path to the JSON file to read.
    
    .EXAMPLE
        Read-JsonFile "config.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        if (!(Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "File does not exist: $FilePath"
            return $null
        }
        
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    }
    catch {
        Write-Warning "Error reading JSON file $FilePath : $($_.Exception.Message)"
        return $null
    }
}

# Write JSON file with proper formatting
function Write-JsonFile {
    <#
    .SYNOPSIS
        Writes an object to a JSON file with proper formatting.
    
    .DESCRIPTION
        Common pattern for writing JSON files with consistent formatting and error handling.
    
    .PARAMETER Object
        The object to convert to JSON.
    
    .PARAMETER FilePath
        The path where the JSON file should be written.
    
    .PARAMETER Compress
        Whether to compress the JSON output (default: $false).
    
    .EXAMPLE
        Write-JsonFile -Object $data -FilePath "output.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Object,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [bool]$Compress = $false
    )
    
    try {
        $jsonContent = $Object | ConvertTo-Json -Depth 10 -Compress:$Compress
        $jsonContent | Out-File -FilePath $FilePath -Encoding UTF8 -Force
        return $true
    }
    catch {
        Write-Warning "Error writing JSON file $FilePath : $($_.Exception.Message)"
        return $false
    }
}

# Get git submodule paths from a git repository
function Get-GitSubmodulePaths {
    <#
    .SYNOPSIS
        Gets the paths of all git submodules in a repository.
    
    .DESCRIPTION
        Checks if a git repository has submodules and returns their paths.
        Returns an empty array if no submodules are found or if git operations fail.
    
    .PARAMETER RepositoryPath
        The path to the git repository to check for submodules.
    
    .EXAMPLE
        Get-GitSubmodulePaths "/Users/dk/Lab_Data/MyRepo"
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )
    
    $submodulePaths = @()
    
    try {
        $originalLocation = Get-Location
        Set-Location $RepositoryPath
        
        # Check if .gitmodules file exists
        $gitmodulesPath = Join-Path $RepositoryPath ".gitmodules"
        if (!(Test-Path -Path $gitmodulesPath -PathType Leaf)) {
            return $submodulePaths
        }
        
        # Get submodule paths using git command
        $gitOutput = git submodule status 2>$null
        if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrEmpty($gitOutput)) {
            $lines = $gitOutput -split "`n" | Where-Object { ![string]::IsNullOrWhiteSpace($_) }
            
            foreach ($line in $lines) {
                # Git submodule status format: " hash path (description)"
                # Extract the path (second field after splitting by spaces)
                $parts = $line.Trim() -split '\s+'
                if ($parts.Count -ge 2) {
                    $submodulePath = $parts[1]
                    $fullSubmodulePath = Join-Path $RepositoryPath $submodulePath
                    
                    if (Test-Path -Path $fullSubmodulePath -PathType Container) {
                        $submodulePaths += $fullSubmodulePath
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Error getting git submodules from $RepositoryPath : $($_.Exception.Message)"
    }
    finally {
        Set-Location $originalLocation
    }
    
    return $submodulePaths
}

# Merge multiple JSON objects with smart handling of arrays and objects
function Merge-JsonObjects {
    <#
    .SYNOPSIS
        Merges multiple JSON objects into a single consolidated object.
    
    .DESCRIPTION
        Takes multiple JSON objects and merges them using these rules:
        - For object values: overwrites (last object wins)
        - For array values: appends all items and removes duplicates
        - Handles nested objects and maintains proper structure
    
    .PARAMETER JsonObjects
        Array of PSCustomObjects to merge (from ConvertFrom-Json).
    
    .EXAMPLE
        $json1 = '{"recommendations": ["ext1", "ext2"], "config": {"setting1": "value1"}}' | ConvertFrom-Json
        $json2 = '{"recommendations": ["ext2", "ext3"], "config": {"setting2": "value2"}}' | ConvertFrom-Json
        Merge-JsonObjects -JsonObjects @($json1, $json2)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$JsonObjects
    )
    
    if ($JsonObjects.Count -eq 0) {
        return [PSCustomObject]@{}
    }
    
    if ($JsonObjects.Count -eq 1) {
        return $JsonObjects[0]
    }
    
    # Start with the first object as base
    $result = [PSCustomObject]@{}
    
    # Get all unique property names across all objects
    $allProperties = @()
    foreach ($obj in $JsonObjects) {
        if ($null -ne $obj -and $obj.PSObject.Properties.Count -gt 0) {
            $allProperties += $obj.PSObject.Properties.Name
        }
    }
    $uniqueProperties = $allProperties | Sort-Object -Unique
    
    # Process each property
    foreach ($property in $uniqueProperties) {
        $propertyValues = @()
        $arrayValues = @()
        $lastObjectValue = $null
        
        # Collect values for this property from all objects
        foreach ($obj in $JsonObjects) {
            if ($null -ne $obj -and $obj.PSObject.Properties.Name -contains $property) {
                $value = $obj.$property
                
                if ($null -ne $value) {
                    $propertyValues += $value
                    $lastObjectValue = $value
                    
                    # If it's an array, collect all items
                    if ($value -is [Array] -or $value.GetType().Name -eq 'Object[]') {
                        $arrayValues += $value
                    }
                }
            }
        }
        
        if ($propertyValues.Count -gt 0) {
            # Determine how to handle this property
            $firstValue = $propertyValues[0]
            
            if ($firstValue -is [Array] -or $firstValue.GetType().Name -eq 'Object[]') {
                # It's an array - concatenate and remove duplicates
                $allArrayItems = @()
                foreach ($arrayValue in $arrayValues) {
                    $allArrayItems += $arrayValue
                }
                
                # Remove duplicates and sort for consistency
                $uniqueItems = $allArrayItems | Sort-Object -Unique
                $result | Add-Member -MemberType NoteProperty -Name $property -Value @($uniqueItems)
            }
            elseif ($firstValue.GetType().Name -eq 'PSCustomObject') {
                # It's an object - use the last one (overwrite behavior)
                $result | Add-Member -MemberType NoteProperty -Name $property -Value $lastObjectValue
            }
            else {
                # It's a primitive value - use the last one (overwrite behavior)
                $result | Add-Member -MemberType NoteProperty -Name $property -Value $lastObjectValue
            }
        }
    }
    
    return $result
}

# Create directory if it doesn't exist
function New-DirectoryIfNotExists {
    <#
    .SYNOPSIS
        Creates a directory if it doesn't already exist.
    
    .DESCRIPTION
        Common pattern for ensuring directories exist before writing files.
    
    .PARAMETER Path
        The directory path to create.
    
    .EXAMPLE
        New-DirectoryIfNotExists "C:\Temp\MyFolder"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        if (!(Test-Path -Path $Path -PathType Container)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            return $true
        }
        return $true
    }
    catch {
        Write-Warning "Error creating directory $Path : $($_.Exception.Message)"
        return $false
    }
}

# Get array of files in a directory (optionally recursive)
function Get-FilesArray {
    <#
    .SYNOPSIS
        Returns an array of file paths from a directory.
    .DESCRIPTION
        Lists all files in the specified directory. Optionally searches recursively.
    .PARAMETER Path
        The directory to search.
    .PARAMETER Recursive
        Whether to search recursively (default: $false).
    .EXAMPLE
        Get-FilesArray -Path "C:\MyRepo" -Recursive $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [bool]$Recursive = $false
    )
    if ($Recursive) {
        return Get-ChildItem -Path $Path -File -Recurse | Select-Object -ExpandProperty FullName
    } else {
        return Get-ChildItem -Path $Path -File | Select-Object -ExpandProperty FullName
    }
}

# Resolve file name conflicts in an array (no git dependency)
function Resolve-FileNameConflicts {
    <#
    .SYNOPSIS
        Resolves file name conflicts by applying suffixes.
    .DESCRIPTION
        Given a list of file names, returns a mapping of original to resolved names, applying _2, _3, etc. for conflicts.
    .PARAMETER FileNames
        Array of file names to resolve.
    .EXAMPLE
        Resolve-FileNameConflicts -FileNames @("file.txt", "file.txt", "file.txt")
        # Returns: @{ "file.txt" = "file.txt"; "file.txt" = "file_2.txt"; "file.txt" = "file_3.txt" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FileNames
    )
    $nameCounts = @{}
    $resolvedNames = @{}
    foreach ($name in $FileNames) {
        if ($nameCounts.ContainsKey($name)) {
            $nameCounts[$name] += 1
            $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
            $ext = [System.IO.Path]::GetExtension($name)
            $newName = "${base}_$($nameCounts[$name])$ext"
            $resolvedNames[$name] = $newName
        } else {
            $nameCounts[$name] = 1
            $resolvedNames[$name] = $name
        }
    }
    return $resolvedNames
}
