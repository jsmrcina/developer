# Adds a folder to PATH for this session and, by default, persists it by adding
# it to the "extraPaths" array of the config file this machine is using so that
# path.ps1 picks it up on every subsequent shell.
#
# -Machine (Windows only) writes to the machine-wide PATH environment variable
# instead, which is the pre-Linux behaviour of this function. It needs elevation.

function global:addpath
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $newPath,
        [switch] $Machine
    )

    if (-not (Test-Path $newPath))
    {
        Write-Error "The specified path does not exist."
        return
    }

    $newPath = (Resolve-Path $newPath).Path

    if ($Machine)
    {
        if (-not (Test-WindowsOnly "-Machine"))
        {
            return
        }

        if (-not (Test-IsElevated))
        {
            Start-Process pwsh -ArgumentList "-NoExit -NoProfile -Command `"& { addpath -newPath `'$newPath`' -Machine }`"" -Verb RunAs
            return
        }

        $currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

        if ($currentPath -split $global:pathSep -contains $newPath)
        {
            Write-Error "The path is already in the machine PATH environment variable."
            return
        }

        [System.Environment]::SetEnvironmentVariable('Path', $currentPath + $global:pathSep + $newPath, [System.EnvironmentVariableTarget]::Machine)
        $env:PATH = $env:PATH + $global:pathSep + $newPath

        Write-Host -ForegroundColor Green "Machine PATH updated successfully."
        return
    }

    # Session
    Add-PathVariable $newPath

    # Persist into the config file for this machine
    if ([string]::IsNullOrWhiteSpace($global:developerConfigFile) -or -not (Test-Path $global:developerConfigFile))
    {
        Write-Warning "No config file loaded, added to this session only."
        return
    }

    $config = Get-Content -Path $global:developerConfigFile -Raw | ConvertFrom-Json

    $existing = @()
    if ($config.PSObject.Properties.Name -contains 'extraPaths')
    {
        $existing = @($config.extraPaths)
    }

    if ($existing -contains $newPath)
    {
        Write-Host -ForegroundColor Blue "$newPath is already in extraPaths."
        return
    }

    $config | Add-Member -MemberType NoteProperty -Name 'extraPaths' -Value ($existing + $newPath) -Force
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $global:developerConfigFile

    Write-Host -ForegroundColor Green "Added $newPath to $global:developerConfigFile."
}
