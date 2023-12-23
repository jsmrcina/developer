# Read the JSON file content
$jsonContent = Get-Content -Path "$PSScriptRoot\config.json" | Out-String

# Parse the JSON content
$jsonObject = ConvertFrom-Json -InputObject $jsonContent

# Loop through the key-value pairs and create variables
foreach ($key in $jsonObject.PSObject.Properties.Name) {
    $value = $jsonObject.$key
    Set-Variable -Name $key -Value $value -Scope Global
}