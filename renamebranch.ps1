function global:renamebranch([string]$newBranchName)
{
    $oldBranchName = git rev-parse --abbrev-ref HEAD
    git branch -m $newBranchName
    git push origin :$oldBranchName $newBranchName
    git push origin -u $newBranchName
}
