# Read configuration file (requires to be in the same directory as this one)
. $PSScriptRoot\read_json.ps1

# Run other config scripts
. $developerFolderPath\aliases.ps1
. $developerFolderPath\config.ps1
. $developerFolderPath\path.ps1
. $developerFolderPath\prompt.ps1

Get-ChildItem "$developerFolderPath\functions" -filter *.ps1 | % {
        . $_.FullName
}

if((Test-Path "$developerFolderPath\pfunctions") -eq $true)
{
  Get-ChildItem "$developerFolderPath\pfunctions" -filter *.ps1 | % {
          . $_.FullName
  }
}