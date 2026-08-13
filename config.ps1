## SSH client
if ($global:isWindowsPlatform)
{
    ## Make sure git is using Windows OpenSSH rather than any git-bundled ssh
    $windowsSsh = Join-Path $env:SystemRoot 'System32/OpenSSH/ssh.exe'
    if (Test-Path $windowsSsh)
    {
        git config --global core.sshCommand $windowsSsh
    }
}
else
{
    ## The ssh on PATH is the right one here. Clear any Windows path that a
    ## previous run (or a copied .gitconfig) may have left behind.
    $currentSshCommand = git config --global --get core.sshCommand
    if ($currentSshCommand -match '\.exe$')
    {
        git config --global --unset core.sshCommand
    }
}

## Make sure powershell Z is installed
if (-not (Get-Module -ListAvailable -Name z))
{
    Write-Host "Installing Z module"
    try
    {
        Install-Module -Name z -Scope CurrentUser -Force -ErrorAction Stop
    }
    catch
    {
        Write-Warning "Could not install the Z module: $($_.Exception.Message)"
    }
}

## Git Configuration
git config --global push.autoSetupRemote true
git config --global rebase.autosquash true

## Editor used for commit messages. Override with "gitEditor" in your config file.
if (-not [string]::IsNullOrWhiteSpace($global:gitEditor))
{
    git config --global core.editor $global:gitEditor
}
elseif ($global:isWindowsPlatform)
{
    git config --global core.editor gvim
}
else
{
    git config --global core.editor vim
}

## Line endings: convert to CRLF on checkout on Windows, store LF only elsewhere
if ($global:isWindowsPlatform)
{
    git config --global core.autocrlf true
}
else
{
    git config --global core.autocrlf input
}
