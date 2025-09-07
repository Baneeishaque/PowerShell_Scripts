<#
.SYNOPSIS
    Automates the process of checking, creating, and launching an Android emulator.

.DESCRIPTION
    This script implements the protocol outlined in the "Android App Launch Protocol" document.
    It checks for Java, verifies if a specific AVD exists, creates it if necessary, and then launches
    the emulator with optimized settings for performance. It then waits for the emulator to boot
    and provides a placeholder for your application launch command.

.NOTES
    - This script is designed for PowerShell Core but has good compatibility with Windows PowerShell.
    - You MUST update the paths for the Android SDK Command-line Tools and Emulator if they are different on your system.
    - The `avdmanager` and `emulator` commands should be in your system's PATH.

.EXAMPLE
    PS C:\> .\run_android_emulator.ps1
    This command executes the full protocol, from AVD creation to app launch.
#>

# Define constants
$avdName = "Android_API_34_ARM64_Phone"
$apiLevel = "34"
$arch = "arm64-v8a"

# Function to check for Java and other dependencies
function Check-Prerequisites {
    Write-Host "Checking for Java and Android SDK dependencies..."

    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        Write-Host "Error: Java is not found. Please install JDK 17 or later." -ForegroundColor Red
        exit 1
    }
    if (-not (Get-Command avdmanager -ErrorAction SilentlyContinue)) {
        Write-Host "Error: avdmanager is not in your PATH. Please ensure the Android SDK Command-line Tools are installed and configured." -ForegroundColor Red
        exit 1
    }
    if (-not (Get-Command emulator -ErrorAction SilentlyContinue)) {
        Write-Host "Error: emulator command is not in your PATH. Please ensure the Android Emulator is installed and configured." -ForegroundColor Red
        exit 1
    }
    Write-Host "Prerequisites met. Proceeding..." -ForegroundColor Green
}

# Function to create an AVD if it doesn't exist
function Create-AvdIfNeeded {
    Write-Host "Checking for existing AVD: $avdName"

    $avdList = avdmanager list avd
    if ($avdList -match $avdName) {
        Write-Host "AVD found. Skipping creation."
    }
    else {
        Write-Host "AVD not found. Creating a new one..."

        # The SDK ID is critical and can be found by running 'sdkmanager --list'
        $sdkId = "system-images;android-$apiLevel;default;$arch"

        # Check if the system image is available
        $sdkList = sdkmanager --list
        if ($sdkList -notmatch $sdkId) {
            Write-Host "System image '$sdkId' is not available. Attempting to install it."
            sdkmanager $sdkId
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error: Failed to install system image. Please check your internet connection or try a different API level/architecture." -ForegroundColor Red
                exit 1
            }
        }

        Write-Host "Creating AVD with name '$avdName' using SDK image '$sdkId'..."
        # The 'echo y |' part is equivalent to 'yes |' in bash for a single 'y'
        echo y | avdmanager create avd -n $avdName -k $sdkId --device "medium_phone"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to create AVD. Check the avdmanager log for details." -ForegroundColor Red
            exit 1
        }
    }
}

# Function to launch the emulator
function Launch-Emulator {
    Write-Host "Launching emulator..."

    # Start the emulator process in the background
    $emulatorProcess = Start-Process -FilePath emulator -ArgumentList "@$avdName", "-memory 4096", "-cores 6", "-gpu auto", "-no-boot-anim", "-no-audio" -NoNewWindow -PassThru -Wait

    Write-Host "Emulator process started with PID $($emulatorProcess.Id)"

    Write-Host "Waiting for emulator to boot up..."
    $timeout = 120
    $startTime = [System.DateTime]::Now

    while (-not (adb devices | Select-String "device$")) {
        $elapsedTime = ([System.DateTime]::Now - $startTime).TotalSeconds
        if ($elapsedTime -ge $timeout) {
            Write-Host "Error: Emulator failed to boot within the timeout period." -ForegroundColor Red
            Stop-Process -Id $emulatorProcess.Id
            exit 1
        }
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 5
    }
    Write-Host ""
    Write-Host "Emulator is ready!" -ForegroundColor Green
}

# Function to run the application
function Run-Application {
    Write-Host "Deploying and launching application..."
    # Replace the command below with your specific application launch command
    # Example for Flutter:
    # flutter run
    # Example for native Android:
    # ./gradlew installDebug

    # Placeholder command for demonstration
    Write-Host "Application launch command would go here."
    Write-Host "Please replace this with your project's specific command."
}

# Main script execution
Check-Prerequisites
Create-AvdIfNeeded
Launch-Emulator
Run-Application

Write-Host "Protocol completed. The Android application should be running on the emulator." -ForegroundColor Green
