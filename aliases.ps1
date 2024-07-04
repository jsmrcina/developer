# Aliases
Function CdToGit { Set-Location -Path $global:gitFolderPath}
Set-Alias -Name cdgit -Value CdToGit

## Global variables
$global:developer_dir = Split-Path $MyInvocation.MyCommand.Path

## Git aliases
git config --global alias.s status
git config --global alias.c commit
git config --global alias.cm '!f() { git commit -m "$1"; }; f'
git config --global alias.cf '!f() { git commit --fixup "$1" -m "$2"; }; f'
git config --global alias.chm '!f() { git checkout -b "$1" origin/main --no-track; }; f'
git config --global alias.a add
git config --global alias.aa '!f() { git add *; }; f'
git config --global alias.rb rebase
git config --global alias.rom '!f() { git fetch; git rebase origin/main; }; f'
git config --global alias.p push
git config --global alias.f fetch
git config --global alias.fp 'fetch --prune'
git config --global alias.l '!f() { git log --pretty=format:"%<|(10)%Cgreen%h%Creset%Cred%<(15,trunc)%an%Creset%<(50,mtrunc)%s" -n$1; }; f'
git config --global alias.la 'log --pretty=format:"%<|(10)%Cgreen%h%Creset%Cred%<(15,trunc)%an%Creset%<(50,mtrunc)%s"'
git config --global alias.br 'branch -vv --all'
git config --global alias.brd '!f() { git branch -D $1; }; f'
git config --global alias.fclean 'clean -xdf'