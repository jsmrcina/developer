function global:selfsquash
{
$ancestor = git merge-base $global:officialBranch HEAD
git reset --soft $ancestor
git commit
}