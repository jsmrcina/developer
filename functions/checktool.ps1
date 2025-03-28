function global:checktool($tool)
{
    $found = Get-Command $tool -ErrorAction SilentlyContinue
    
    if (-not $found)
    {
        Write-Host -ForegroundColor Red "$tool was not found, make sure it is in your PATH."
        return $false
    }

    return $true
}