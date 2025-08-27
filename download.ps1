#!pwsh
<#
.SYNOPSIS
    Demonstrates and times different methods for downloading a file in PowerShell.

.DESCRIPTION
    This script shows three different ways to download a file from a URL:
    1. Invoke-WebRequest: The modern, standard PowerShell cmdlet.
    2. System.Net.WebClient: A .NET class, common in older scripts.
    3. Start-BitsTransfer: Uses the Background Intelligent Transfer Service (BITS), which is robust for large files and unreliable networks.

    Each method is timed and the result is printed to the console. The script is pre-configured with a test URL.
    By default, only the Invoke-WebRequest method is active. Uncomment the other sections to test them.

.NOTES
    - The BITS method requires the 'BitsTransfer' module, which is available on Windows client operating systems but may not be on Windows Server by default.
#>

param()

$url = "http://mirror.internode.on.net/pub/test/10meg.test"
$output = Join-Path -Path $PSScriptRoot -ChildPath "10meg.test"

# --- Method 1: Invoke-WebRequest (Modern PowerShell) ---
Write-Host "--- Testing Invoke-WebRequest ---" -ForegroundColor Cyan
$start_time = Get-Date
Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction Stop
Write-Output "Time taken: $((Get-Date).Subtract($start_time).TotalSeconds) second(s)"
if (Test-Path -Path $output) { Remove-Item -Path $output -Force } # Clean up for the next test

# --- Method 2: System.Net.WebClient (.NET Class) ---
# Write-Host "`n--- Testing System.Net.WebClient ---" -ForegroundColor Cyan
# $start_time = Get-Date
# try {
#     $wc = New-Object System.Net.WebClient
#     $wc.DownloadFile($url, $output)
#     Write-Output "Time taken: $((Get-Date).Subtract($start_time).TotalSeconds) second(s)"
# }
# finally {
#     if ($wc) { $wc.Dispose() }
#     if (Test-Path -Path $output) { Remove-Item -Path $output -Force } # Clean up
# }

# --- Method 3: Start-BitsTransfer (Background Intelligent Transfer Service) ---
# if ($IsWindows) {
#     Write-Host "`n--- Testing Start-BitsTransfer ---" -ForegroundColor Cyan
#     $start_time = Get-Date
#     Import-Module BitsTransfer -ErrorAction Stop
#     Start-BitsTransfer -Source $url -Destination $output -ErrorAction Stop
#     Write-Output "Time taken: $((Get-Date).Subtract($start_time).TotalSeconds) second(s)"
#     if (Test-Path -Path $output) { Remove-Item -Path $output -Force } # Clean up
# } else {
#     Write-Host "`n--- Skipping Start-BitsTransfer (Not on Windows) ---" -ForegroundColor Yellow
# }
