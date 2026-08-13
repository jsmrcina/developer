# Loads the machine-specific config file into global variables.
# $global:developerConfigFile is set by the _<location>.ps1 file your profile sources.

if ([string]::IsNullOrWhiteSpace($global:developerConfigFile))
{
    Write-Warning "`$global:developerConfigFile is not set. Source one of the _<location>.ps1 files (e.g. _linux.ps1) from your profile before source.ps1."
    return
}

if (-not (Test-Path $global:developerConfigFile))
{
    Write-Warning "Config file not found: $global:developerConfigFile"
    return
}

# Read and parse the JSON file content
$jsonObject = Get-Content -Path $global:developerConfigFile -Raw | ConvertFrom-Json

# Loop through the key-value pairs and create variables
foreach ($key in $jsonObject.PSObject.Properties.Name) {
    # developerFolderPath is derived from $PSScriptRoot in source.ps1, never from config
    if ($key -eq 'developerFolderPath')
    {
        continue
    }

    Set-Variable -Name $key -Value $jsonObject.$key -Scope Global
}
