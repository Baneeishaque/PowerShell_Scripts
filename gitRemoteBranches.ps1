#!pwsh
$branches = git for-each-ref --format='%(refname:short)' refs/remotes/origin
# Write-Output $branches
foreach ($branch in $branches)
{
    # Write-Output $branch
    if(-not(($branch -Contains "origin/HEAD") -or ($branch -Contains "origin/master") -or ($branch -Contains "origin/pyup-scheduled-update-2022-12-18") -or ($branch -Contains "origin/restyled/pyup-scheduled-update-2022-12-18")))
    {
        $splitOutput = $branch -split '/',2
        # Write-Output $splitOutput[0]
        # Write-Output $splitOutput[1]
        # Write-Output "push -d $splitOutput"
        Start-Process -FilePath "git" -ArgumentList "push -d $splitOutput" -NoNewWindow -Wait
    }
}
