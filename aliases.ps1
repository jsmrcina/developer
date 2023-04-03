# Aliases
Function CdToGit { Set-Location -Path $global:gitFolderPath}
Set-Alias -Name cdgit -Value CdToGit

# Add items to path
Function Add-PathVariable {
    param (
        [string]$addPath
    )

    if (Test-Path $addPath)
    {
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env:Path -split ';' | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $env:Path = ($arrPath + $addPath) -join ';'
    }
    else
    {
        Throw "'$addPath' is not a valid path."
    }
}

## Sublime
Add-PathVariable "C:\Program Files\Sublime Text 3"

## Global variables
$global:developer_dir = Split-Path $MyInvocation.MyCommand.Path
