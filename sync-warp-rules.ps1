#Requires -Version 5.1
<#
.SYNOPSIS
    Smart sync for Warp AI Agent rules documentation
.DESCRIPTION
    Prepares and validates Warp AI rules sync to agent-rules.md with git integration.
    Checks if rules file is clean and ready for sync. Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.
.PARAMETER Force
    Reserved for future use (currently unused)
.PARAMETER Quiet
    Run silently without output
.EXAMPLE
    ./sync-warp-rules.ps1
    ./sync-warp-rules.ps1 -Force
    ./sync-warp-rules.ps1 -Quiet
#>

param(
    [switch]$Force,
    [switch]$Quiet
)

# Import common utilities via dot-sourcing (DRY principle)
$scriptDirectory = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDirectory "Common-Utils.ps1")

# Configuration
$RulesDir = Join-Path $env:HOME "Lab_Data/Warp-AI-Rules"
$RulesFile = Join-Path $RulesDir "agent-rules.md"

# Main sync function
try {
    # Check if rules directory exists
    if (-not (Test-Path $RulesDir)) {
        Write-Message "❌ Rules directory not found: $RulesDir" "Red" -Quiet:$Quiet
        exit 1
    }

    # Check if rules file exists
    if (-not (Test-Path $RulesFile)) {
        Write-Message "❌ Rules file not found: $RulesFile" "Red" -Quiet:$Quiet
        exit 1
    }

    Write-Message "📝 Initiating Warp AI rules sync..." "Green" -Quiet:$Quiet
    
    # Check if rules file has uncommitted changes
    $IsGitRepo = Test-GitRepository $RulesDir
    $RulesFileClean = $true
    $CanCommit = $false
    
    if ($IsGitRepo) {
        $RulesFileClean = Test-FileClean $RulesFile
        $CanCommit = Test-GitClean $RulesDir
        
        if (-not $RulesFileClean) {
            Write-Message "⚠️  Rules file (agent-rules.md) has uncommitted changes!" "Yellow" -Quiet:$Quiet
            Write-Message "   This could interfere with sync. Consider committing first." "Gray" -Quiet:$Quiet
            exit 1
        }
    }

    Write-Message "✅ Ready to sync rules documentation!" "Green" -Quiet:$Quiet
    Write-Message "📋 Next steps:" "Cyan" -Quiet:$Quiet
    Write-Message "   1. Tell Warp Agent: 'Update agent-rules.md with current rules'" "White" -Quiet:$Quiet
    Write-Message "   2. Agent will update the file and commit automatically" "Gray" -Quiet:$Quiet
    
    if ($IsGitRepo) {
        Write-Message "📊 Git Status:" "Cyan" -Quiet:$Quiet
        Write-Message "   • Rules file: $(if ($RulesFileClean) { 'Clean ✅' } else { 'Modified ⚠️' })" "Gray" -Quiet:$Quiet
        Write-Message "   • Repository: $(if ($CanCommit) { 'Clean - can commit ✅' } else { 'Has changes - will skip commit/push ⚠️' })" "Gray" -Quiet:$Quiet
    }

    exit 0
}
catch {
    Write-Message "❌ Sync failed: $($_.Exception.Message)" "Red" -Quiet:$Quiet
    exit 1
}
