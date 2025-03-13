# Read configuration file (requires to be in the same directory as this one)
. $PSScriptRoot\read_json.ps1

# Run other config scripts
. $developerFolderPath\aliases.ps1
. $developerFolderPath\config.ps1
. $developerFolderPath\path.ps1
. $developerFolderPath\prompt.ps1

$global:dev_functions = @()
$global:pdev_functions = @()

$before = (Get-Command -CommandType Function).Name
Get-ChildItem "$developerFolderPath\functions" -filter *.ps1 | % {
        . $_.FullName
}
$after = (Get-Command -CommandType Function).Name

$newFunctions = $after | Where-Object { $before -notcontains $_ }
$global:dev_functions += $newFunctions

if((Test-Path "$developerFolderPath\pfunctions") -eq $true)
{
  $before = (Get-Command -CommandType Function).Name
  Get-ChildItem "$developerFolderPath\pfunctions" -filter *.ps1 | % {
          . $_.FullName
  }
  $after = (Get-Command -CommandType Function).Name

  $newFunctions = $after | Where-Object { $before -notcontains $_ }
  $global:pdev_functions += $newFunctions
}