# Aliases
Function CdToGit { Set-Location -Path $global:gitFolderPath}
Set-Alias -Name cdgit -Value CdToGit

## Global variables
$global:developer_dir = Split-Path $MyInvocation.MyCommand.Path

## Git aliases
git config --global alias.s status
git config --global alias.c commit
git config --global alias.ch checkout
git config --global alias.a add
git config --global alias.rb rebase
git config --global alias.p push
git config --global alias.f fetch
git config --global alias.l10 'log --pretty=format:"%<|(10)%Cgreen%h%Creset%Cred%<(15,trunc)%an%Creset%<(50,mtrunc)%s" -n10'
git config --global alias.br 'branch -vv --all'