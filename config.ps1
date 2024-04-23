## Make sure git is using Windows OpenSSH
git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

## Make sure powershell Z is installed
if (-not (Get-Module -ListAvailable -Name z))
{
    Write-Host "Installing Z module"
    Install-Module -Name z  
}

git config --global alias.s status
git config --global alias.c commit
git config --global alias.ch checkout
git config --global alias.a add
git config --global alias.rb rebase
git config --global alias.p push
git config --global alias.f fetch
git config --global alias.l10 'log --pretty=format:"%h`t`t%s" -n10'
git config --global alias.br 'branch -vv'