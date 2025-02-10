function addpath
{
    param
    (
        [string] $newPath
    )

    if (-not (Test-Path $newPath))
    {
        Write-Error "The specified path does not exist."
        return
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin)
    {
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -Command `"& { addpath -NewPath `'$NewPath`' }`"" -Verb RunAs
        return
    }

    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    if ($currentPath -split ';' -contains $newPath)
    {
        Write-Error "The path is already in the PATH environment variable."
        return
    }

    $updatedPath = $currentPath + ";" + $newPath

    [System.Environment]::SetEnvironmentVariable('Path', $updatedPath, [System.EnvironmentVariableTarget]::Machine)

    $sessionPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Process)
    $sessionPath = $sessionPath + ";" + $newPath
    [System.Environment]::SetEnvironmentVariable('Path', $sessionPath, [System.EnvironmentVariableTarget]::Process)

    Write-Console -ForegroundColor Green "Path updated successfully."
}