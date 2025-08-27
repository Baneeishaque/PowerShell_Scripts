#!pwsh
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

# Recursively remove duplicates from arrays in a PSCustomObject or hashtable
function Remove-DuplicatesFromArrays {
    <#
    .SYNOPSIS
        Recursively removes duplicate items from arrays in an object.
    .DESCRIPTION
        Walks through all properties of an object, and for any array, removes duplicate items.
        Handles arrays of primitives and arrays of objects (by JSON string comparison).
        Recurses into nested objects and arrays.
    .PARAMETER InputObject
        The object to process.
    .EXAMPLE
        $deduped = Remove-DuplicatesFromArrays $object
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )
    if ($null -eq $InputObject) { return $InputObject }

    if ($InputObject -is [System.Collections.IEnumerable] -and
        $InputObject.GetType().Name -ne 'String') {
        # It's an array (but not a string)
        $unique = @()
        $seen = @{}
        foreach ($item in $InputObject) {
            # For objects, use JSON string as key; for primitives, use value
            if ($item -is [PSCustomObject] -or $item -is [Hashtable]) {
                $key = $item | ConvertTo-Json -Compress
            } else {
                $key = $item
            }
            if (-not $seen.ContainsKey($key)) {
                $unique += ,$item
                $seen[$key] = $true
            }
        }
        # Recursively deduplicate items in the array
        return $unique | ForEach-Object { Remove-DuplicatesFromArrays $_ }
    } elseif ($InputObject -is [PSCustomObject] -or $InputObject -is [Hashtable]) {
        # It's an object
        $output = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $output[$prop.Name] = Remove-DuplicatesFromArrays $prop.Value
        }
        return [PSCustomObject]$output
    } else {
        # Primitive value
        return $InputObject
    }
}

# Write JSON file with proper formatting and optional deduplication
function Write-JsonFile {
    <#
    .SYNOPSIS
        Writes an object to a JSON file with proper formatting.
    .DESCRIPTION
        Common pattern for writing JSON files with consistent formatting and error handling.
        Optionally removes duplicate items from arrays before writing.
    .PARAMETER Object
        The object to convert to JSON.
    .PARAMETER FilePath
        The path where the JSON file should be written.
    .PARAMETER Compress
        Whether to compress the JSON output (default: $false).
    .PARAMETER SkipDeduplication
        If set, skips deduplication of arrays before writing.
    .EXAMPLE
        Write-JsonFile -Object $data -FilePath "output.json"
        Write-JsonFile -Object $data -FilePath "output.json" -SkipDeduplication $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Object,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [bool]$Compress = $false,

        [Parameter(Mandatory = $false)]
        [bool]$SkipDeduplication = $false
    )

    try {
        $objectToWrite = if ($SkipDeduplication) { $Object } else { Remove-DuplicatesFromArrays $Object }
        $jsonContent = $objectToWrite | ConvertTo-Json -Depth 10 -Compress:$Compress
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
        Robustly merges multiple JSON objects with strict type and array item type validation.

    .DESCRIPTION
        - For each unique property, ensures all values are of the same type.
        - For arrays, ensures all arrays have the same item type, and deduplicates by value.
        - For primitives/objects, always overwrites with the latest value.
        - Exits with a clear error if any type or array item type mismatch is found.

    .PARAMETER JsonObjects
        Array of PSCustomObjects to merge (from ConvertFrom-Json).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$JsonObjects
    )

    if ($JsonObjects.Count -eq 0) { return [PSCustomObject]@{} }
    if ($JsonObjects.Count -eq 1) { return $JsonObjects[0] }

    $result = [ordered]@{}
    $allProperties = @()
    foreach ($obj in $JsonObjects) {
        if ($null -ne $obj -and $obj.PSObject.Properties.Count -gt 0) {
            $allProperties += $obj.PSObject.Properties.Name
        }
    }
    # Write-Message "Found $($allProperties.Count) properties across all JSON objects" "Gray"
    # foreach ($property in $allProperties) {
    #     Write-Message "Found Property: $($property | ConvertTo-Json -Depth 3)" "Gray"
    # }
    # exit 0

    $uniqueProperties = $allProperties | Sort-Object -Unique
    # Write-Message "Found $($uniqueProperties.Count) unique properties across all JSON objects" "Gray"
    # foreach ($property in $uniqueProperties) {
    #     Write-Message "Found unique property: $property" "Gray"
    # }
    # exit 0

    foreach ($property in $uniqueProperties) {
        # Write-Message "Processing property: $property" "Gray"
        $values = @()
        foreach ($obj in $JsonObjects) {
            if ($null -ne $obj -and $obj.PSObject.Properties.Name -contains $property) {
                $values += ,$obj.$property
            }
        }
        # Write-Message "Found $($values.Count) values for property '$property'" "Gray"
        # Write-Message "Found values: $($values | ConvertTo-Json -Depth 3)" "Gray"
        # exit 0

        if ($values.Count -eq 0) { continue }

        # Determine type
        $types = @($values | ForEach-Object { if ($_ -eq $null) { "null" } else { $_.GetType().Name } } | Sort-Object -Unique)
        # Write-Message "Found types for property '$property': $types" "Gray"
        # Write-Message "Types: $($types -join ', ')" "Gray"
        # Write-Message "Types Data Type: $($types.GetType().Name)" "Gray"
        # exit 0
        # Write-Message "Types Count: $($types.Count)" "Gray"
        if ($types.Count -gt 1) {
            Write-Error "Type mismatch for property '$property': found types $($types -join ', ')"
            exit 1
        }
        $type = $types[0]
        # Write-Message "Using type '$type' for property '$property'" "Gray"
        # exit 0

        if ($type -eq "Object[]" -or $type -eq "Array") {
            # Validate all arrays have the same item type
            $allItems = @()
            $itemTypes = @()
            foreach ($arr in $values) {
                # Write-Message "Processing value for property '$property': $($arr | ConvertTo-Json -Depth 3)" "Gray"
                if ($arr -eq $null) { continue }
                foreach ($item in $arr) {
                    # Write-Message "Found item: $($item | ConvertTo-Json -Depth 3)" "Gray"
                    $allItems += ,$item
                    # Write-Message "Found all items: $($allItems | ConvertTo-Json -Depth 3)" "Gray"
                    $typeName = if ($item -eq $null) { "null" } else { $item.GetType().Name }
                    $itemTypes += ,$typeName
                }
            }
            $itemTypes = @($itemTypes | Sort-Object -Unique)
            # Write-Message "Array item types: $($itemTypes -join ', ')" "Gray"
            # Write-Message "Array item types data type: $($itemTypes.GetType().Name)" "Gray"
            # Write-Message "Array item types count: $($itemTypes.Count)" "Gray"
            if ($itemTypes.Count -gt 1) {
                Write-Error "Array item type mismatch for property '$property': found item types $($itemTypes -join ', ')"
                exit 1
            }
            $itemType = $itemTypes[0]
            # Write-Message "Using item type '$itemType' for property '$property'" "Gray"
            # exit 0
            # Deduplicate by value
            if ($itemType -eq "String" -or $itemType -eq "Int32" -or $itemType -eq "Double" -or $itemType -eq "Boolean") {
                $uniqueItems = $allItems | Sort-Object -Unique
                $result[$property] = @($uniqueItems)
            } else {
                # For objects, deduplicate by JSON string
                $seen = @{}
                $uniqueItems = @()
                foreach ($item in $allItems) {
                    $key = if ($item -is [PSCustomObject] -or $item -is [Hashtable]) {
                        $item | ConvertTo-Json -Compress
                    } else {
                        $item
                    }
                    if (-not $seen.ContainsKey($key)) {
                        $uniqueItems += ,$item
                        $seen[$key] = $true
                    }
                }
                $result[$property] = @($uniqueItems)
            }
        } elseif ($type -eq "String" -or $type -eq "Int32" -or $type -eq "Double" -or $type -eq "Boolean" -or $type -eq "Hashtable" -or $type -eq "PSCustomObject") {
            # Use the last value
            $result[$property] = $values[-1]
        } elseif ($type -eq "null") {
            $result[$property] = $null
        } else {
            Write-Error "Unsupported type '$type' for property '$property'"
            exit 1
        }
        # Write-Message "Final merged property '$property': $($result[$property] | ConvertTo-Json -Depth 3)" "Gray"
        # exit 0
    }
    # Write-Message "Final merged JSON object: $($result | ConvertTo-Json -Depth 3)" "Gray"
    # exit 0

    return [PSCustomObject]$result
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
