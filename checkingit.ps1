function global:checkingit([string]$repourl)
{
    gci | ForEach-Object { if(-not (Test-Path "$_\.git")) { Write-Host "$_ is not in Git" } }
}
