# Source all the files under $developerFolderPath

param(
[string]$developerFolderPath = "C:\Users\jsmrc\Documents\Git\developer",
[string]$gitFolderPath = "C:\Users\jsmrc\Documents\Git")

# Make available to other scripts
$global:gitFolderPath = $gitFolderPath

Get-ChildItem $developerFolderPath | % {
    if($_.Name -ne "source.ps1")
	{
        . $_.FullName
    }
}