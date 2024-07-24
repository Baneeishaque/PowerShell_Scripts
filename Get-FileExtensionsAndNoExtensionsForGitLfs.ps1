$scriptDirectory = Split-Path -Parent $PSCommandPath

. "$scriptDirectory\Get-FileExtensionsAndNoExtensions.ps1"

$dirExtensionsWithNoExtensionFiles = Get-FileExtensionsAndNoExtensions
#$dirExtensionsWithNoExtensionFiles

$dirExtensions = $dirExtensionsWithNoExtensionFiles[0] | ForEach-Object { $_.TrimStart('.') }
#$dirExtensions

# Get extensions from .gitattributes
# TODO: Filter already present no extension files too.
$gitAttrExtensions = Get-Content .\.gitattributes | ForEach-Object {if ($_ -match "\*\.(.+) filter") {$matches[1]}}

# Define a list of common extensions
$commonExtensions = @('gitattributes', 'txt', 'csv', 'json', 'css', 'html', 'svg', 'gif', 'jpg', 'nfo', 'png', 'webp', 'avif', 'pem', 'sql')

# Combine common extensions and gitAttrExtensions
$combinedExtensions = $commonExtensions + $gitAttrExtensions

# Filter the dirExtensions list to only include those not present in combinedExtensions
$filteredDirExtensions = $dirExtensions | Where-Object {$combinedExtensions -notcontains $_}

$filteredDirExtensionsWithNoExtensionFiles = $filteredDirExtensions + $dirExtensionsWithNoExtensionFiles[1]

# Output the filtered list
$filteredDirExtensionsWithNoExtensionFiles
