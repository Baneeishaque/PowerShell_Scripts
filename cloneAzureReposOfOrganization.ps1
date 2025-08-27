# Log in to Azure DevOps
# az devops login

# List all projects in the organization
$adoprojs = az devops project list --organization https://dev.azure.com/banee-ishaque-k-azure-devops-works
$projObjs = $adoprojs | ConvertFrom-Json

# Iterate through each project
foreach ($proj in $projObjs.value) {
    write-host "Looking in $($proj.name) ADO project for repos"

    # List all repositories in the project
    $jsonRepos = az repos list --organization https://dev.azure.com/banee-ishaque-k-azure-devops-works --project $proj.name
    $RepoObjs = $jsonRepos | ConvertFrom-Json

    # Iterate through each repository
    foreach ($repo in $RepoObjs) {
        write-host "  " $repo.name
        write-host "  " $repo.size
        write-host "  " $repo.webUrl

        # Clone the repository if its size is greater than 0
        if ($repo.size -gt 0) {
            git clone $repo.remoteUrl
        }
    }
}
