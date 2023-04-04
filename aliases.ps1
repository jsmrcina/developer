# Aliases
Function CdToGit { Set-Location -Path $global:gitFolderPath}
Set-Alias -Name cdgit -Value CdToGit

## Global variables
$global:developer_dir = Split-Path $MyInvocation.MyCommand.Path