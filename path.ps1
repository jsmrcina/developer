# Add items to path
Function Add-PathVariable {
    param (
        [string]$addPath
    )

    if ([string]::IsNullOrEmpty($addPath))
    {
        return
    }

    if (Test-Path $addPath)
    {
        # Drop any existing entry for this path (with or without a trailing
        # separator) before re-appending it, so PATH never accumulates dupes.
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $ENV:PATH -split $global:pathSep | Where-Object {$_ -notMatch "^$regexAddPath[\\/]?$"}
        $ENV:PATH = ($arrPath + $addPath) -join $global:pathSep
    }
}

function Set-VariableFromArgument {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [object]$Value
    )

    Set-Variable -Name $Name -Value $Value -Scope Global
}

# Tool paths from the config file. Anything not defined for this machine is
# skipped, so a config only needs the entries that actually apply to it.
Add-PathVariable $editorPath
Add-PathVariable $githubClPath
Add-PathVariable $godotPath
Add-PathVariable $dotnetPath

# Arbitrary extra entries, so a machine can add paths without editing this file
foreach ($extraPath in $global:extraPaths)
{
    Add-PathVariable $extraPath
}

if ($null -ne $mainBranchName)
{
    Set-VariableFromArgument -Name "officialBranch" -Value $mainBranchName
}
else
{
    Set-VariableFromArgument -Name "officialBranch" -Value "main"
}

if ($null -ne $developerUnrealPath)
{
    Set-VariableFromArgument -Name "developerUnrealPath" -Value $developerUnrealPath
}
