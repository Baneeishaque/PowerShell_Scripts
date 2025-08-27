#!pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Installs a Homebrew formula, prioritizing the HEAD version and falling back to a source build.

.DESCRIPTION
    This script installs a specified Homebrew formula with a specific priority:
    1. It first checks if a '--HEAD' version (the latest development version) is available.
    2. If a HEAD version is found, it installs it using 'brew install --HEAD'.
    3. If a HEAD version is not available, it falls back to installing the formula by building it from source using 'brew install --build-from-source'.

    This script is useful for developers who want the latest code or need to compile a formula with specific options on their machine.

.PARAMETER Formula
    The name of the Homebrew formula to install. This parameter is mandatory.

.EXAMPLE
    .\Install-HomebrewFormula.ps1 -Formula neovim
    This command will attempt to install the HEAD version of 'neovim'. If not available, it will build 'neovim' from source.

.EXAMPLE
    .\Install-HomebrewFormula.ps1 -Formula ripgrep
    This command will attempt to install the HEAD version of 'ripgrep'. If not available, it will build 'ripgrep' from source.

.NOTES
    - Requires Homebrew to be installed and accessible in the system's PATH.
    - Uses functions from 'Common-Utils.ps1' for consistent logging and command checking.
    - The script will exit if Homebrew is not found or if the specified formula does not exist.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "The name of the Homebrew formula to install.")]
    [string]$Formula
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import common utilities from the same directory
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    . (Join-Path $scriptDir "Common-Utils.ps1")
}
catch {
    Write-Error "Failed to load 'Common-Utils.ps1'. Make sure it is in the same directory as this script."
    exit 1
}

try {
    Write-Message "🍺 Attempting to install '$Formula' from Homebrew with custom priority..." "Cyan"

    # 1. Check for Homebrew using the common utility function
    if (-not (Test-CommandExists "brew")) {
        Write-Message "❌ Error: Homebrew is not installed. Please install it from https://brew.sh/" "Red"
        exit 1
    }

    # 2. Check if the formula exists
    Write-Message "🔍 Verifying formula '$Formula' exists..." "Gray"
    $infoOutput = & brew info $Formula 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Message "❌ Error: Formula '$Formula' not found in Homebrew or an error occurred." "Red"
        Write-Message "Details: $infoOutput" "Gray"
        exit 1
    }
    Write-Message "✅ Formula '$Formula' found." "Green"

    # 3. Get detailed formula info as JSON to check for a HEAD version
    Write-Message "🔍 Analyzing available versions for '$Formula'..." "Cyan"
    $jsonInfo = & brew info --json=v2 $Formula | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Message "❌ Error: Failed to get detailed JSON info for '$Formula'." "Red"
        exit 1
    }

    # 4. Check if the 'head' property is present and not null
    if ($null -ne $jsonInfo.formulae[0].head) {
        Write-Message "✅ HEAD version is available for '$Formula'." "Green"
        Write-Message "🚀 Installing with 'brew install --HEAD $Formula' (this may take a while)..." "Magenta"
        & brew install --HEAD $Formula --verbose
    } else {
        Write-Message "ℹ️ HEAD version is not available for '$Formula'." "Yellow"
        Write-Message "🔧 Falling back to building from source as requested..." "Magenta"
        Write-Message "🚀 Installing with 'brew install --build-from-source $Formula' (this may take a while)..." "Magenta"
        & brew install --build-from-source $Formula --verbose
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Message "🎉 Successfully installed '$Formula'." "Green"
    } else {
        Write-Message "❌ Failed to install '$Formula'." "Red"
        exit 1
    }
}
catch {
    Write-Message "❌ An unexpected error occurred: $($_.Exception.Message)" "Red"
    exit 1
}
