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
    else
    {
        Throw "'$addPath' is not a valid path."
    }
}

## Sublime
## TODO: Move path to non-checked in config file
Add-PathVariable "C:\Program Files\Sublime Text 3"