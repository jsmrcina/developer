# Squashes the current branch into a single commit. Useful for squash merge based repositories before you rebase onto main
function global:selfsquash
{
$ancestor = git merge-base $global:officialBranch HEAD
git reset --soft $ancestor
git commit
}