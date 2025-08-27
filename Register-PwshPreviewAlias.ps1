#!pwsh
<#
.SYNOPSIS
    Creates a symbolic link to make the 'pwsh' command execute PowerShell Preview.

.DESCRIPTION
    This script finds the executable for PowerShell Preview ('pwsh-preview') and creates a
    symbolic link named 'pwsh' pointing to it in '/usr/local/bin'. This allows you to run
    'pwsh' in your terminal and have it launch the preview version by default.

    This is intended for non-Windows systems (macOS, Linux) where '/usr/local/bin' is
    a standard location for user-installed executables and is typically in the system's PATH.

    Administrator/sudo privileges are required to create a link in this directory.

.EXAMPLE
    sudo pwsh -File ./Register-PwshPreviewAlias.ps1
    Checks for pwsh-preview and attempts to create the symbolic link. You must run this with
    sudo for it to have the necessary permissions.

.NOTES
    - This script will overwrite any existing file or link at /usr/local/bin/pwsh.
    - This script is not intended for Windows.
#>
[CmdletBinding()]
param()

# Set strict mode for better error handling
Set-StrictMode -Version Latest

if ($IsWindows) {
    Write-Error "This script is for macOS/Linux and is not intended for Windows."
    exit 1
}

Write-Host "Attempting to set 'pwsh' command to point to PowerShell Preview..." -ForegroundColor Cyan

try {
    $pwshPreviewPath = (Get-Command pwsh-preview -ErrorAction Stop).Source
    Write-Host "✅ Found PowerShell Preview executable at: $pwshPreviewPath" -ForegroundColor Green

    $linkPath = "/usr/local/bin/pwsh"
    Write-Host "Attempting to create symbolic link at '$linkPath'..." -ForegroundColor Yellow

    New-Item -ItemType SymbolicLink -Path $linkPath -Target $pwshPreviewPath -Force -ErrorAction Stop | Out-Null

    Write-Host "🎉 Successfully created symbolic link." -ForegroundColor Magenta
    Write-Host "Please restart your terminal or run 'hash -r' for changes to take effect." -ForegroundColor Magenta
}
catch {
    Write-Error "❌ Failed to create symbolic link. Error: $($_.Exception.Message)"
    Write-Error "💡 Please ensure you are running this script with sudo privileges (e.g., 'sudo pwsh -File ./Register-PwshPreviewAlias.ps1')."
    exit 1
}
