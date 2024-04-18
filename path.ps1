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
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $ENV:PATH -split $pathSep | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $ENV:PATH = ($arrPath + $addPath) -join $pathSep
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

## Sublime
## TODO: Move path to non-checked in config file
Add-PathVariable $editorPath
Add-PathVariable $githubClPath
Add-PathVariable $godotPath
Add-PathVariable $dotnetPath

Set-VariableFromArgument -Name "officialBranch" -Value $mainBranchName
Set-VariableFromArgument -Name "developerUnrealPath" -Value $developerUnrealPath