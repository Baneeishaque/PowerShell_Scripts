#!pwsh
function Get-FileExtensionsAndNoExtensions {
    param([string]$folderPath = (Get-Location).Path)

    # Get all files in the folder and its subfolders
    $files = Get-ChildItem -Path $folderPath -File -Recurse

    # Initialize an empty array to hold the extensions
    $extensions = @()

    # Initialize an empty array to hold the paths of files without extensions
    $noExtensionFiles = @()

    foreach ($file in $files) {
        if ($file.Extension) {
            # If the file has an extension, add it to the extensions array
            $extensions += $file.Extension
        } else {
            # If the file does not have an extension, add its path to the noExtensionFiles array
            $noExtensionFiles += $file.FullName
        }
    }

    # Get the unique extensions
    $uniqueExtensions = $extensions | Sort-Object | Get-Unique

    return $uniqueExtensions, $noExtensionFiles
}
