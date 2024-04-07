$scriptDirectory = Split-Path -Parent $PSCommandPath

. "$scriptDirectory\Get-FileExtensionsAndNoExtensions.ps1"

# Get all file extensions in the directory using your function
$dirExtensions = Get-FileExtensionsAndNoExtensions | ForEach-Object { $_.TrimStart('.') }
# $dirExtensions

# Get extensions from .gitattributes
$gitAttrExtensions = Get-Content .\.gitattributes | ForEach-Object {if ($_ -match "\*\.(.+) filter") {$matches[1]}}

# Define a list of common extensions
$commonExtensions = @('gitattributes', 'gif', 'jpg', 'nfo', 'png', 'webp', 'avif')

# Combine common extensions and gitAttrExtensions
$combinedExtensions = $commonExtensions + $gitAttrExtensions

# Filter the dirExtensions list to only include those not present in combinedExtensions
$filteredDirExtensions = $dirExtensions | Where-Object {$combinedExtensions -notcontains $_}

# Output the filtered list
$filteredDirExtensions
