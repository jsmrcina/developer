## Make sure git is using Windows OpenSSH
git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

## Make sure powershell Z is installed
if (-not (Get-Module -ListAvailable -Name z))
{
    Write-Host "Installing Z module"
    Install-Module -Name z  
}

## Git Configuration
git config --global push.autoSetupRemote true
git config --global core.editor gvim
git config --global rebase.autosquash true
git config --global core.autocrlf true