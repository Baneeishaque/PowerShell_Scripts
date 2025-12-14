#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restores VS Code Insiders user configuration from a backup using rclone.
.DESCRIPTION
    This script restores the VS Code Insiders user configuration from a
    pre-existing backup. It first performs a dry run to show what files
    will be copied, asks for user confirmation, and then executes the actual restore.
    It also checks for dependencies like rclone and Homebrew, offering to install them.
.NOTES
    Author: Gemini Code Assist
    Requires: rclone to be installed and in the system's PATH.
#>

Write-Host "🚀 Starting VS Code Insiders Restore Process..." -ForegroundColor Cyan

# --- Imports and Dependency Checks ---
. "$PSScriptRoot/common-utils.ps1"
Ensure-Dependencies

# --- Configuration ---
$BackupSource = "$HOME/Lab_Data/configurations-private/vscode-insiders-configuration-backup"
$VSCodeUserConfigDest = "$HOME/Library/Application Support/Code - Insiders/User/"

# --- Pre-flight Checks ---
if (-not (Test-Path -Path $BackupSource)) {
    Write-Error "❌ Backup source directory not found at '$BackupSource'. Cannot restore."
    exit 1
}

# --- Dry Run ---
Write-Host "`n🔍 Performing a dry run of the restore. No files will be changed." -ForegroundColor Green
Write-Host "The following files would be copied from backup to your live configuration:"
rclone copy $BackupSource $VSCodeUserConfigDest --dry-run --progress

# --- Confirmation ---
Write-Host "" # Add a newline for spacing
$confirmation = Read-Host "❓ Do you want to proceed with the actual restore? This will overwrite existing configuration files. (y/n)"

if ($confirmation -eq 'y') {
    # --- Actual Restore ---
    Write-Host "`n⚡ Executing the actual restore..." -ForegroundColor Green
    pkill -f "Code - Insiders" # Ensure VS Code is not running
    Write-Host "Closed VS Code Insiders to prevent file conflicts."

    rclone copy $BackupSource $VSCodeUserConfigDest --progress
    
    Write-Host "`n✅ Restore complete. You can now start VS Code Insiders." -ForegroundColor Green
} else {
    Write-Host "`n❌ Restore cancelled by user." -ForegroundColor Red
}
