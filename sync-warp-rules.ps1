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

# Configuration
$RulesDir = Join-Path $env:HOME "Lab_Data/Warp-AI-Rules"
$RulesFile = Join-Path $RulesDir "agent-rules.md"

function Write-Message {
    param([string]$Message, [string]$Color = "White")
    if (-not $Quiet) {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Host $Message -ForegroundColor $Color
        } else {
            # Windows PowerShell compatibility
            Write-Host $Message
        }
    }
}

function Test-GitRepository {
    param([string]$Path)
    return Test-Path (Join-Path $Path ".git")
}

function Test-GitClean {
    param([string]$Path)
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

function Test-FileClean {
    param([string]$FilePath)
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

# Main sync function
try {
    # Check if rules directory exists
    if (-not (Test-Path $RulesDir)) {
        Write-Message "❌ Rules directory not found: $RulesDir" "Red"
        exit 1
    }

    # Check if rules file exists
    if (-not (Test-Path $RulesFile)) {
        Write-Message "❌ Rules file not found: $RulesFile" "Red"
        exit 1
    }

    Write-Message "📝 Initiating Warp AI rules sync..." "Green"
    
    # Check if rules file has uncommitted changes
    $IsGitRepo = Test-GitRepository $RulesDir
    $RulesFileClean = $true
    $CanCommit = $false
    
    if ($IsGitRepo) {
        $RulesFileClean = Test-FileClean $RulesFile
        $CanCommit = Test-GitClean $RulesDir
        
        if (-not $RulesFileClean) {
            Write-Message "⚠️  Rules file (agent-rules.md) has uncommitted changes!" "Yellow"
            Write-Message "   This could interfere with sync. Consider committing first." "Gray"
            exit 1
        }
    }

    Write-Message "✅ Ready to sync rules documentation!" "Green"
    Write-Message "" 
    Write-Message "📋 Next steps:" "Cyan"
    Write-Message "   1. Tell Warp Agent: 'Update agent-rules.md with current rules'" "White"
    Write-Message "   2. Agent will update the file and commit automatically" "Gray"
    
    if ($IsGitRepo) {
        Write-Message ""
        Write-Message "📊 Git Status:" "Cyan"
        Write-Message "   • Rules file: $(if ($RulesFileClean) { 'Clean ✅' } else { 'Modified ⚠️' })" "Gray"
        Write-Message "   • Repository: $(if ($CanCommit) { 'Clean - can commit ✅' } else { 'Has changes - will skip commit/push ⚠️' })" "Gray"
    }

    exit 0
}
catch {
    Write-Message "❌ Sync failed: $($_.Exception.Message)" "Red"
    exit 1
}
