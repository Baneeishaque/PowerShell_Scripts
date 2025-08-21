# Ensure AWS Tools for PowerShell is loaded
Import-Module AWSPowerShell.NetCore -ErrorAction Stop

# ==== CONFIGURATION ====
$AccessKey  = "YOUR_AWS_ACCESS_KEY"
$SecretKey  = "YOUR_AWS_SECRET_KEY"
$BucketName = "your-bucket-name"  # Change to your bucket name

# ==== RELATIVE PATHS ====
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LocalFilePath = Join-Path $ScriptDir "sample-image.jpg"
$S3Key = "sample-image.jpg"
$DownloadPath = Join-Path $ScriptDir "downloaded-image.jpg"

try {
    # ==== UPLOAD FILE ====
    Write-Host "⬆️ Uploading $LocalFilePath to s3://$BucketName/$S3Key ..." -ForegroundColor Cyan
    $BucketRegion = (Get-S3BucketLocation -BucketName $BucketName -AccessKey $AccessKey -SecretKey $SecretKey).Value
    if (-not $BucketRegion) { $BucketRegion = "us-east-1" } # null means us-east-1
    $Region = $BucketRegion

    Write-S3Object -BucketName $BucketName -File $LocalFilePath -Key $S3Key -Region $Region -AccessKey $AccessKey -SecretKey $SecretKey
    Write-Host "✅ Upload complete." -ForegroundColor Green

    # ==== VERIFY UPLOAD ====
    $uploaded = Get-S3Object -BucketName $BucketName -Key $S3Key -Region $Region -AccessKey $AccessKey -SecretKey $SecretKey
    if ($uploaded) {
        Write-Host "📦 File exists in S3. Size: $($uploaded.Size) bytes, LastModified: $($uploaded.LastModified)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Upload verification failed." -ForegroundColor Red
        exit
    }

    # ==== DOWNLOAD FILE ====
    Write-Host "⬇️ Downloading s3://$BucketName/$S3Key to $DownloadPath ..." -ForegroundColor Cyan
    Read-S3Object -BucketName $BucketName -Key $S3Key -File $DownloadPath -Region $Region -AccessKey $AccessKey -SecretKey $SecretKey
    Write-Host "✅ Download complete." -ForegroundColor Green

} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
