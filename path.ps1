# Add items to path
Function Add-PathVariable {
    param (
        [string]$addPath
    )

    if (Test-Path $addPath)
    {
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $ENV:PATH -split $pathSep | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $ENV:PATH = ($arrPath + $addPath) -join $pathSep
    }
}

## Sublime
## TODO: Move path to non-checked in config file
Add-PathVariable $sublimePath
Add-PathVariable $githubClPath
Add-PathVariable $godotPath
Add-PathVariable $dotnetPath