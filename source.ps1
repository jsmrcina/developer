# Source all the files under $developerFolderPath

param(
[string]$developerFolderPath = "I:\Documents\Git\developer",
[string]$gitFolderPath = "I:\Documents\Git")

# Make available to other scripts
$global:gitFolderPath = $gitFolderPath

Get-ChildItem $developerFolderPath -filter *.ps1 | % {
    if($_.Name -ne "source.ps1")
    {
        . $_.FullName
    }
}