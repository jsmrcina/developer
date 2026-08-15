# Platform helpers must come first, everything below depends on them
. (Join-Path $PSScriptRoot 'platform.ps1')

# The developer folder is wherever this script lives, no need to configure it
$global:developerFolderPath = $PSScriptRoot

# Read configuration file (requires to be in the same directory as this one)
. (Join-Path $PSScriptRoot 'read_json.ps1')

# Run other config scripts
. (Join-Path $PSScriptRoot 'aliases.ps1')
. (Join-Path $PSScriptRoot 'config.ps1')
. (Join-Path $PSScriptRoot 'path.ps1')
. (Join-Path $PSScriptRoot 'prompt.ps1')
. (Join-Path $PSScriptRoot 'keybindings.ps1')

$global:dev_functions = @()
$global:pdev_functions = @()

$before = (Get-Command -CommandType Function).Name
Get-ChildItem (Join-Path $PSScriptRoot 'functions') -Filter *.ps1 | ForEach-Object {
        . $_.FullName
}
$after = (Get-Command -CommandType Function).Name

$newFunctions = $after | Where-Object { $before -notcontains $_ }
$global:dev_functions += $newFunctions

$privateFunctionPath = Join-Path $PSScriptRoot 'pfunctions'
if (Test-Path $privateFunctionPath)
{
  $before = (Get-Command -CommandType Function).Name
  Get-ChildItem $privateFunctionPath -Filter *.ps1 | ForEach-Object {
          . $_.FullName
  }
  $after = (Get-Command -CommandType Function).Name

  $newFunctions = $after | Where-Object { $before -notcontains $_ }
  $global:pdev_functions += $newFunctions
}
