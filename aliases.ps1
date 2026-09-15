# Aliases
Function CdToGit { Set-Location -Path $global:gitFolderPath}
Set-Alias -Name cdgit -Value CdToGit

if (-not $global:isWindowsPlatform) {
    # dc [path] - open path (default: current directory) in Double Commander, detached from the terminal
    Function OpenDoubleCommander {
        param([string]$Path = (Get-Location).ProviderPath)
        $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
        # sh does the redirect: a pwsh-side redirect pipes DC's output and pwsh blocks until DC exits.
        # DC's OnlyOneAppInstance hands the path to the running instance as a new tab.
        & sh -c 'setsid -f doublecmd -T "$1" >/dev/null 2>&1' sh $resolved
    }
    Set-Alias -Name dc -Value OpenDoubleCommander
}

# Private Aliases
$privateAliases = Join-Path $PSScriptRoot 'p_aliases.ps1'
if (Test-Path -Path $privateAliases) {
    . $privateAliases
}

# Global variables
$global:developer_dir = $PSScriptRoot

## Git aliases
git config --global alias.s status
git config --global alias.c commit
git config --global alias.cm '!f() { git commit -m "$1"; }; f'
git config --global alias.cf '!f() { git commit --fixup "$1" -m "$2"; }; f'
git config --global alias.chm '!f() { git checkout -b "$1" origin/main --no-track; }; f'
git config --global alias.a add
git config --global alias.aa 'add --all'
git config --global alias.rb rebase
git config --global alias.rom '!f() { git fetch; git rebase origin/main; }; f'
git config --global alias.p push
git config --global alias.f fetch
git config --global alias.fp 'fetch --prune'
git config --global alias.l '!f() { git log --pretty=format:"%<|(15)%Cgreen%h%Creset%Cred%<(15,trunc)%an%Creset%<(50,mtrunc)%s" -n$1; }; f'
git config --global alias.la 'log --pretty=format:"%<|(10)%Cgreen%h%Creset%Cred%<(15,trunc)%an%Creset%<(50,mtrunc)%s"'
git config --global alias.br 'branch -vv --all'
git config --global alias.brd '!f() { git branch -D $1; }; f'
git config --global alias.fclean 'clean -xdf'
