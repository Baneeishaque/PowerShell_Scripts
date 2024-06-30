# will be prompted to log in via browser
# az login

# get all your ADO projects in your org in json format
$adoprojs = az devops project list --organization https://dev.azure.com/banee-ishaque-k-azure-devops-works

# convert to powershell object
$projObjs = $adoprojs | ConvertFrom-Json

# loop through each ADO project and find it's repos
foreach ($proj in $projObjs.value.name) {
	write-host "looking in $proj ADO project for repos"
	# set to specific ADO project
	az devops configure --defaults organization=https://dev.azure.com/banee-ishaque-k-azure-devops-works project=$proj
	# now get it's repos (in json)
	$jsonRepos = az repos list
	# convert repos from json format to powershell object
	$RepoObjs = $jsonRepos | ConvertFrom-Json
	# now list each repo
	foreach ($repo in $RepoObjs) {
		write-host "  " $repo.name
	}
}