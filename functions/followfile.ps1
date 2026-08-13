function global:followfile($fileName)
{
    if (-not (checktool "gitk"))
    {
        return
    }

    gitk --all --first-parent --remotes --reflog --author-date-order -- $fileName
}
