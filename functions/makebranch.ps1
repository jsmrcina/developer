# Creates a branch locally and remotely

function global:makebranch([string]$branchName)
{
    $fullBranchName = "$branchName"
    Write-Host "Full branch name = $fullBranchName"
    git fetch
    git checkout -b $fullBranchName main
    git push -u origin HEAD
}