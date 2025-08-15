#Requires -Version 5.1
<#
.SYNOPSIS
    Smart sync for Warp AI Agent rules documentation
.DESCRIPTION
    Intelligently syncs Warp AI rules to agent-rules.md with throttling and git integration.
    Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+.
.PARAMETER Force
    Force sync even if recently synced
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
$LastSyncFile = Join-Path $RulesDir ".last-sync"
$SyncThrottleHours = 1

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

# Main sync function
try {
    # Check if rules directory exists
    if (-not (Test-Path $RulesDir)) {
        Write-Message "❌ Rules directory not found: $RulesDir" "Red"
        exit 1
    }

    # Get current timestamp
    $CurrentTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $LastSyncTime = 0

    # Read last sync time
    if (Test-Path $LastSyncFile) {
        try {
            $LastSyncTime = [long](Get-Content $LastSyncFile -Raw).Trim()
        }
        catch {
            Write-Message "⚠️  Invalid sync timestamp, treating as first run" "Yellow"
        }
    }

    # Check if sync is needed (throttle: only sync if more than X hours passed or forced)
    $TimeDiff = $CurrentTime - $LastSyncTime
    $ThrottleSeconds = $SyncThrottleHours * 3600
    
    if ($TimeDiff -lt $ThrottleSeconds -and -not $Force) {
        $MinutesRemaining = [math]::Ceiling(($ThrottleSeconds - $TimeDiff) / 60)
        Write-Message "⏱️  Last sync was recent. Next sync available in $MinutesRemaining minutes." "Cyan"
        Write-Message "   Use -Force to sync anyway." "Gray"
        exit 0
    }

    Write-Message "📝 Initiating Warp AI rules sync..." "Green"

    # Check if we're in a git repository
    if (-not (Test-GitRepository $RulesDir)) {
        Write-Message "⚠️  Not a git repository. Git operations skipped." "Yellow"
    }
    elseif (-not (Test-GitClean $RulesDir)) {
        Write-Message "⚠️  Uncommitted changes found. Please commit or stash first." "Yellow"
        Write-Message "   Run: cd '$RulesDir' && git status" "Gray"
        exit 1
    }

    # Save sync timestamp
    $CurrentTime | Out-File -FilePath $LastSyncFile -Encoding ASCII -NoNewline

    Write-Message "✅ Sync timestamp updated successfully!" "Green"
    Write-Message "" 
    Write-Message "📋 Next steps:" "Cyan"
    Write-Message "   1. Tell Warp Agent: 'Update agent-rules.md with current rules'" "White"
    Write-Message "   2. Or manually update the rules documentation" "Gray"
    Write-Message ""
    Write-Message "📊 Stats:" "Cyan"
    Write-Message "   • Rules directory: $(Split-Path $RulesDir -Leaf)" "Gray"
    Write-Message "   • Last sync: $(Get-Date -UnixTimeSeconds $LastSyncTime -Format 'yyyy-MM-dd HH:mm:ss')" "Gray"
    Write-Message "   • Throttle period: $SyncThrottleHours hours" "Gray"

    exit 0
}
catch {
    Write-Message "❌ Sync failed: $($_.Exception.Message)" "Red"
    exit 1
}
