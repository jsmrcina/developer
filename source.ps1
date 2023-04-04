# Source all the files under $developerFolderPath

# TODO: Move to non-checked in file
param(
[string]$developerFolderPath = "C:\Users\jsmrc\Documents\git\developer",
[string]$gitFolderPath = "C:\Users\jsmrc\Documents\git")

# Make available to other scripts
$global:gitFolderPath = $gitFolderPath

# Run other config scripts
. $developerFolderPath\aliases.ps1
. $developerFolderPath\config.ps1
. $developerFolderPath\path.ps1

Get-ChildItem "$developerFolderPath\functions" -filter *.ps1 | % {
        . $_.FullName
}