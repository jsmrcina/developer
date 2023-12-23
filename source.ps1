# Read configuration file (requires to be in the same directory as this one)
. $PSScriptRoot\read_json.ps1

# Run other config scripts
. $developerFolderPath\aliases.ps1
. $developerFolderPath\config.ps1
. $developerFolderPath\path.ps1

Get-ChildItem "$developerFolderPath\functions" -filter *.ps1 | % {
        . $_.FullName
}