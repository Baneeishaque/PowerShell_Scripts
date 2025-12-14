#!/usr/bin/env pwsh
<#
.SYNOPSIS
    A collection of common utility functions for PowerShell scripts.
.DESCRIPTION
    This script contains reusable functions that can be dot-sourced by other scripts.
.NOTES
    Author: Gemini Code Assist
#>

function Ensure-Dependencies {
    # Check for rclone
    if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
        Write-Host "❗️ rclone command not found." -ForegroundColor Yellow

        # Check for Homebrew
        if (Get-Command brew -ErrorAction SilentlyContinue) {
            Write-Host "🍺 Homebrew is installed." -ForegroundColor Green
            $confirmRclone = Read-Host "❓ Do you want to install rclone using Homebrew? (y/n)"
            if ($confirmRclone -eq 'y') {
                Write-Host "Installing rclone via Homebrew..."
                brew install rclone
            } else {
                Write-Error "❌ rclone is required to proceed. Please install it manually and run the script again."
                exit 1
            }
        } else {
            Write-Host "🍺 Homebrew is not installed, which is the recommended way to install rclone." -ForegroundColor Yellow
            $confirmBrew = Read-Host "❓ Do you want to install Homebrew now? (This will also attempt to install rclone afterward) (y/n)"
            if ($confirmBrew -eq 'y') {
                Write-Host "Installing Homebrew..."
                & /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                Write-Host "Installing rclone via Homebrew..."
                brew install rclone
            } else {
                Write-Error "❌ Homebrew and rclone are required. Please install them manually and run the script again."
                exit 1
            }
        }
    }
}