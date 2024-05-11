# Lists each local branch and lets you decide if you want to keep or delete it

function global:pruneremotes
{
    git remote prune origin
}