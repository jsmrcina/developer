# Dumps the first 10 commits on a specific filename
function global:initial_commits($fileName)
{
    git log --follow --pretty=format:"%H" -- $fileName | ForEach-Object { $_ } | Select-Object -Last 10
}