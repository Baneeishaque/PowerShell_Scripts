$scriptDirectory = Split-Path -Parent $PSCommandPath

. "$scriptDirectory\Get-FileExtensionsAndNoExtensions.ps1"

$dirExtensionsWithNoExtensionFiles = Get-FileExtensionsAndNoExtensions
#$dirExtensionsWithNoExtensionFiles

$dirExtensions = $dirExtensionsWithNoExtensionFiles[0] | ForEach-Object { $_.TrimStart('.') }
# $dirExtensions.GetType()
#$dirExtensions

# Get extensions from .gitattributes
# TODO: Filter already present no extension files too.
$gitAttrExtensions = Get-Content .\.gitattributes | ForEach-Object {if ($_ -match "\*\.(.+) filter") {$matches[1]}}
# $gitAttrExtensions.GetType()

# Define a list of common extensions
$commonExtensions = @('gitattributes', 'txt', 'csv', 'json', 'css', 'html', 'svg', 'gif', 'jpg', 'nfo', 'png', 'webp', 'avif', 'pem', 'sql')

# Combine common extensions and gitAttrExtensions
$combinedExtensions = $commonExtensions + $gitAttrExtensions
# $combinedExtensions.GetType()

# Filter the dirExtensions list to only include those not present in combinedExtensions
$filteredDirExtensions = $dirExtensions | Where-Object {$combinedExtensions -notcontains $_}
# $filteredDirExtensions.GetType()

$filteredDirExtensionsWithNoExtensionFiles = $filteredDirExtensions + $dirExtensionsWithNoExtensionFiles[1]
# Write-Output (Get-Location).Path
# Write-Output "$([Environment]::NewLine)"
# $dirExtensionsWithNoExtensionFiles[1][0]
# Write-Output "$([Environment]::NewLine)"
# $dirExtensionsWithNoExtensionFiles[1][0]


# Output the filtered list
# $filteredDirExtensionsWithNoExtensionFiles.GetType()
# Write-Output "$([Environment]::NewLine)"
# $filteredDirExtensionsWithNoExtensionFiles[1]
$filteredDirExtensionsWithNoExtensionFiles
