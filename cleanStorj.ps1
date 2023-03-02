# TODO : Use CommandLine Arguments for $rcloneConfiguartionPath
$rcloneConfiguartionPath = "C:\Lab_Data\configurations-private\rclone.conf"
# $iterationCount = 0;
function ProcessFolders {
    param (
        $path
    )
    # Write-Output $path
    # Write-Output $iterationCount
    $folders = rclone lsf $path --config $rcloneConfiguartionPath
    # Write-Output $folders
    foreach ($folder in $folders) {
        # if($iterationCount -ne 2){
        # Write-Output $folder
        # $iterationCount++
        $currentSeperator = $folder.Substring($folder.Length - 1)
        # Write-Output $currentSeperator
        if ($currentSeperator -eq "/") {
            ProcessFolders -path "$path$folder"
            # Write-Output "rclone purge $path$folder --config $rcloneConfiguartionPath"
            rclone purge $path$folder --config $rcloneConfiguartionPath
        }
        # }
    }
}

# TODO : Use CommandLine Arguments for $path
ProcessFolders -path "Storj-Banee3-Gmail:"
