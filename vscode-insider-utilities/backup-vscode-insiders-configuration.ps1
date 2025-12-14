#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Backs up VS Code Insiders user configuration using rclone.
.DESCRIPTION
    This script performs a synchronized backup of the VS Code Insiders user
    configuration directory. It first performs a dry run to show what changes
    will be made, asks for user confirmation, and then executes the actual sync.
.NOTES
    Author: Gemini Code Assist
    Requires: rclone to be installed and in the system's PATH.
#>

Write-Host "🚀 Starting VS Code Insiders Backup Process..." -ForegroundColor Cyan

# --- Imports and Dependency Checks ---
. "$PSScriptRoot/common-utils.ps1"
Ensure-Dependencies

# --- Configuration ---
# Define source and destination paths
$VSCodeUserConfig = "$HOME/Library/Application Support/Code - Insiders/User/"
$BackupDest = "$HOME/Lab_Data/configurations-private/vscode-insiders-configuration-backup"

# Define rclone exclusion filters
$RcloneExcludes = @(
    "--exclude=/mcp/**",
    "--exclude=globalStorage/**",
    "--exclude=/workspaceStorage/**",
    "--exclude=/state.vscdb",
    "--exclude=/CachedData/**",
    "--exclude=/Backups/**",
    "--exclude=/sync/**",
    "--exclude=/History/**",
    "--exclude=.DS_Store"
)

# --- Pre-flight Checks ---
if (-not (Test-Path -Path $BackupDest)) {
    Write-Host "Backup destination not found. Creating directory: $BackupDest" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackupDest | Out-Null
}

# --- Dry Run ---
Write-Host "`n🔍 Performing a dry run of the backup. No files will be changed." -ForegroundColor Green
rclone sync $VSCodeUserConfig $BackupDest --create-empty-src-dirs @RcloneExcludes --dry-run --progress

# --- Confirmation ---
Write-Host "" # Add a newline for spacing
$confirmation = Read-Host "❓ Do you want to proceed with the actual backup? (y/n)"

if ($confirmation -eq 'y') {
    # --- Actual Backup ---
    Write-Host "`n⚡ Executing the actual backup..." -ForegroundColor Green
    rclone sync $VSCodeUserConfig $BackupDest --create-empty-src-dirs @RcloneExcludes --progress
    Write-Host "`n✅ Backup complete." -ForegroundColor Green
} else {
    Write-Host "`n❌ Backup cancelled by user." -ForegroundColor Red
}
