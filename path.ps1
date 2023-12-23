# Add items to path
Function Add-PathVariable {
    param (
        [string]$addPath
    )

    if (Test-Path $addPath)
    {
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env:Path -split ';' | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $env:Path = ($arrPath + $addPath) -join ';'
    }
}

## Sublime
## TODO: Move path to non-checked in config file
Add-PathVariable $sublimePath
Add-PathVariable $githubClPath