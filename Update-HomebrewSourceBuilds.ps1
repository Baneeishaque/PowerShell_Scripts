#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Homebrew updater for all formulas and casks including HEAD, source builds, and greedy updates.

.DESCRIPTION
    This script performs a complete Homebrew update including:
    - Regular formula and cask updates
    - HEAD version updates (latest development versions)
    - Source-built formula updates with --build-from-source flag
    - Greedy cask updates (auto-updating applications)
    - Verbose logging for maximum visibility
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.

.PARAMETER Force
    Force rebuild all source-built formulas even if they're already up-to-date.

.PARAMETER ListOnly
    Only list the formulas without updating them.

.PARAMETER SkipUpdate
    Skip the initial 'brew update' step (useful if recently updated).

.PARAMETER SkipGreedy
    Skip greedy cask updates (faster execution).

.PARAMETER SkipCleanup
    Skip cleanup after updates.

.PARAMETER Quiet
    Run silently without output.

.EXAMPLE
    Update-HomebrewSourceBuilds.ps1
    Updates all source-built formulas to their latest versions.

.EXAMPLE
    Update-HomebrewSourceBuilds.ps1 -Force
    Force rebuilds all source-built formulas from source regardless of version.

.EXAMPLE
    Update-HomebrewSourceBuilds.ps1 -ListOnly
    Lists all formulas that were built from source without updating them.

.EXAMPLE
    Update-HomebrewSourceBuilds.ps1 -Quiet
    Runs silently without output.

.NOTES
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.
    Requires Homebrew to be installed and accessible in PATH.
    Uses maximum logging (--verbose) for detailed build information.
    Reuses common utility functions via dot-sourcing for DRY principle.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Force rebuild all source-built formulas even if up-to-date")]
    [switch]$Force,
    
    [Parameter(HelpMessage = "Only list formulas without updating them")]
    [switch]$ListOnly,
    
    [Parameter(HelpMessage = "Skip the initial brew update step")]
    [switch]$SkipUpdate,
    
    [Parameter(HelpMessage = "Skip greedy cask updates")]
    [switch]$SkipGreedy,
    
    [Parameter(HelpMessage = "Skip cleanup after updates")]
    [switch]$SkipCleanup,
    
    [Parameter(HelpMessage = "Run silently without output")]
    [switch]$Quiet
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import common utilities via dot-sourcing (DRY principle)
$scriptDirectory = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDirectory "Common-Utils.ps1")

# Function to get HEAD version formulas
function Get-HeadFormulas {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    Write-Message "🔍 Identifying HEAD version formulas..." "Cyan" -Quiet:$Quiet
    
    try {
        $headFormulas = brew list --versions | Select-String "HEAD-" | ForEach-Object {
            ($_ -split '\s+')[0]
        }
        
        if ($headFormulas) {
            $count = ($headFormulas | Measure-Object).Count
            Write-Message "Found $count HEAD formulas:" "Green" -Quiet:$Quiet
            foreach ($formula in $headFormulas) {
                Write-Message "  • $formula" "Yellow" -Quiet:$Quiet
            }
            return $headFormulas
        } else {
            Write-Message "No HEAD formulas found." "Yellow" -Quiet:$Quiet
            return @()
        }
    }
    catch {
        Write-Message "❌ Error identifying HEAD formulas: $($_.Exception.Message)" "Red" -Quiet:$Quiet
        throw
    }
}

# Function to get formulas built from source (excluding HEAD to avoid duplicates)
function Get-SourceBuiltFormulas {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeFormulas = @()
    )
    
    Write-Message "🔍 Identifying source-built formulas..." "Cyan" -Quiet:$Quiet
    
    try {
        # Get formulas that were not built as bottles (i.e., built from source)
        $sourceFormulasJson = & brew info --installed --json
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get Homebrew formula information"
        }
        
        $allSourceFormulas = $sourceFormulasJson | ConvertFrom-Json | Where-Object { 
            $_.installed[0].built_as_bottle -eq $false 
        } | Select-Object -ExpandProperty name
        
        # Filter out excluded formulas (like HEAD versions) to avoid duplicates
        $sourceFormulas = $allSourceFormulas | Where-Object { $_ -notin $ExcludeFormulas }
        
        if ($sourceFormulas) {
            $count = ($sourceFormulas | Measure-Object).Count
            Write-Message "Found $count source-built formulas (excluding HEAD):" "Green" -Quiet:$Quiet
            foreach ($formula in $sourceFormulas) {
                Write-Message "  • $formula" "Yellow" -Quiet:$Quiet
            }
            return $sourceFormulas
        } else {
            Write-Message "No source-built formulas found (excluding HEAD versions)." "Yellow" -Quiet:$Quiet
            return @()
        }
    }
    catch {
        Write-Message "❌ Error identifying source-built formulas: $($_.Exception.Message)" "Red" -Quiet:$Quiet
        throw
    }
}

# Function to update source-built formulas
function Update-SourceFormulas {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Formulas,
        
        [Parameter(Mandatory = $false)]
        [bool]$ForceRebuild = $false
    )
    
    if ($Formulas.Count -eq 0) {
        Write-Message "No formulas to update." "Yellow" -Quiet:$Quiet
        return
    }
    
    $action = if ($ForceRebuild) { "reinstall" } else { "upgrade" }
    $actionDescription = if ($ForceRebuild) { "Force rebuilding" } else { "Updating" }
    
    Write-Message "🔨 $actionDescription source-built formulas with verbose logging..." "Cyan" -Quiet:$Quiet
    
    foreach ($formula in $Formulas) {
        Write-Message "📦 $actionDescription $formula..." "Magenta" -Quiet:$Quiet
        
        try {
            if ($ForceRebuild) {
                & brew reinstall $formula --build-from-source --verbose
            } else {
                & brew upgrade $formula --build-from-source --verbose
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Message "✅ Successfully processed $formula" "Green" -Quiet:$Quiet
            } else {
                Write-Message "⚠️ $formula completed with warnings (exit code: $LASTEXITCODE)" "Yellow" -Quiet:$Quiet
            }
        }
        catch {
            Write-Message "❌ Error processing $formula`: $($_.Exception.Message)" "Red" -Quiet:$Quiet
        }
    }
}

# Main execution
try {
    Write-Message "🍺 Comprehensive Homebrew Updater" "Green" -Quiet:$Quiet
    Write-Message "=================================" "Green" -Quiet:$Quiet
    
    # Check if Homebrew is available using reusable function
    if (-not (Test-CommandExists "brew")) {
        Write-Message "❌ Homebrew not found in PATH. Please install Homebrew first." "Red" -Quiet:$Quiet
        exit 1
    }
    
    # Step 1: Update Homebrew itself and formulae/casks definitions
    if (-not $SkipUpdate) {
        Write-Message "📥 Updating Homebrew and formulae definitions..." "Cyan" -Quiet:$Quiet
        & brew update --verbose
        if ($LASTEXITCODE -ne 0) {
            Write-Message "⚠️ Brew update had issues, but continuing..." "Yellow" -Quiet:$Quiet
        }
    } else {
        Write-Message "⏭️ Skipping brew update (--SkipUpdate specified)" "Yellow" -Quiet:$Quiet
    }
    
    # Step 2: Get all formula types
    Write-Message "📋 Analyzing installed formulas..." "Cyan" -Quiet:$Quiet
    $headFormulas = Get-HeadFormulas
    $sourceFormulas = Get-SourceBuiltFormulas -ExcludeFormulas $headFormulas
    
    if ($ListOnly) {
        Write-Message "📋 List-only mode - no updates performed." "Cyan" -Quiet:$Quiet
        Write-Message "📊 Summary:" "Cyan" -Quiet:$Quiet
        Write-Message "   • HEAD formulas: $($headFormulas.Count)" "White" -Quiet:$Quiet
        Write-Message "   • Source-built formulas: $($sourceFormulas.Count)" "White" -Quiet:$Quiet
        return
    }
    
    # Step 3: Update HEAD formulas first (they include latest development versions)
    if ($headFormulas.Count -gt 0) {
        Write-Message "🚀 Updating HEAD formulas (latest development versions)..." "Cyan" -Quiet:$Quiet
        foreach ($formula in $headFormulas) {
            Write-Message "📦 Updating HEAD formula: $formula..." "Magenta" -Quiet:$Quiet
            try {
                & brew upgrade $formula --verbose
                if ($LASTEXITCODE -eq 0) {
                    Write-Message "✅ Successfully updated $formula" "Green" -Quiet:$Quiet
                } else {
                    Write-Message "⚠️ $formula completed with warnings" "Yellow" -Quiet:$Quiet
                }
            }
            catch {
                Write-Message "❌ Error updating $formula`: $($_.Exception.Message)" "Red" -Quiet:$Quiet
            }
        }
    }
    
    # Step 4: Update source-built formulas
    if ($sourceFormulas.Count -gt 0) {
        Update-SourceFormulas -Formulas $sourceFormulas -ForceRebuild $Force.IsPresent
    }
    
    # Step 5: Update all remaining formulas (regular bottle installs)
    Write-Message "🔄 Updating all remaining formulas..." "Cyan" -Quiet:$Quiet
    & brew upgrade --verbose
    if ($LASTEXITCODE -eq 0) {
        Write-Message "✅ Formula updates completed" "Green" -Quiet:$Quiet
    } else {
        Write-Message "⚠️ Some formula updates had issues" "Yellow" -Quiet:$Quiet
    }
    
    # Step 6: Update all casks (including greedy ones)
    Write-Message "🖥️ Updating casks..." "Cyan" -Quiet:$Quiet
    if (-not $SkipGreedy) {
        Write-Message "🔄 Updating casks with greedy flag (auto-updating apps)..." "Cyan" -Quiet:$Quiet
        & brew upgrade --cask --greedy --verbose
    } else {
        Write-Message "🔄 Updating casks (without greedy flag)..." "Cyan" -Quiet:$Quiet
        & brew upgrade --cask --verbose
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Message "✅ Cask updates completed" "Green" -Quiet:$Quiet
    } else {
        Write-Message "⚠️ Some cask updates had issues" "Yellow" -Quiet:$Quiet
    }
    
    # Step 7: Cleanup (unless skipped)
    if (-not $SkipCleanup) {
        Write-Message "🧹 Cleaning up..." "Cyan" -Quiet:$Quiet
        & brew cleanup --verbose
        & brew autoremove --verbose
        Write-Message "✅ Cleanup completed" "Green" -Quiet:$Quiet
    } else {
        Write-Message "⏭️ Skipping cleanup (--SkipCleanup specified)" "Yellow" -Quiet:$Quiet
    }
    
    # Step 8: Final status
    Write-Message "🎉 Comprehensive Homebrew update completed!" "Green" -Quiet:$Quiet
    Write-Message "💡 Run 'brew doctor' to check for any issues" "Cyan" -Quiet:$Quiet
    
    # Show summary
    Write-Message "📊 Update Summary:" "Cyan" -Quiet:$Quiet
    Write-Message "   • HEAD formulas: $($headFormulas.Count)" "White" -Quiet:$Quiet
    Write-Message "   • Source-built formulas: $($sourceFormulas.Count)" "White" -Quiet:$Quiet
    Write-Message "   • Greedy cask updates: $(if ($SkipGreedy) { 'Skipped' } else { 'Included' })" "White" -Quiet:$Quiet
}
catch {
    Write-Message "❌ Fatal error: $($_.Exception.Message)" "Red" -Quiet:$Quiet
    exit 1
}
