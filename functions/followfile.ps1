function global:followfile($fileName)
{
    gitk --all --first-parent --remotes --reflog --author-date-order -- $fileName
}