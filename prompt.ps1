function prompt
{
    $gitBranch = ''
    try
    {
        git rev-parse --show-toplevel 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0)
        {
            $branch = git rev-parse --abbrev-ref HEAD
            $red = "$([char]27)[31m"
            $reset = "$([char]27)[0m"
            $gitBranch = "${red}[$branch]${reset} "
        }
    }
    catch {}

    $newline = [System.Environment]::NewLine
    $location = Get-Location

    # 'A' marks an elevated session (Administrator on Windows, root elsewhere)
    $elevatedMarker = if (Test-IsElevated) { 'A ' } else { '' }

    return $newline + $gitBranch + $newline + $location + $newline + $elevatedMarker + '>> '
}
