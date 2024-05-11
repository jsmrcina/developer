# Creates a branch locally and remotely

function global:makebranch([string]$branchName, [bool]$fromMain = $false)
{
    $fullBranchName = "$branchName"
    Write-Host "Full branch name = $fullBranchName"
    git fetch

    if($fromMain)
    {
        git checkout -b $fullBranchName origin/main
    }
    else
    {
        git checkout -b $fullBranchName
    }

    git push -u origin HEAD
}