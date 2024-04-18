# Rebases the current branch onto the official branch
function global:rebasetopic
{
git pull --rebase origin $global:officialBranch
}

