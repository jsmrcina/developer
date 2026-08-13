# Platform detection and cross-platform helpers.
# This is sourced first by source.ps1 so everything else can rely on it.

# $IsWindows/$IsLinux/$IsMacOS only exist in PowerShell 6+. Windows PowerShell 5.1
# reports PSEdition 'Desktop' (or nothing at all) and can only ever be Windows.
if ($PSVersionTable.PSEdition -ne 'Core')
{
    $global:isWindowsPlatform = $true
    $global:isLinuxPlatform = $false
    $global:isMacOSPlatform = $false
}
else
{
    $global:isWindowsPlatform = $IsWindows
    $global:isLinuxPlatform = $IsLinux
    $global:isMacOSPlatform = $IsMacOS
}

# Separator between entries in $env:PATH: ';' on Windows, ':' everywhere else
$global:pathSep = [System.IO.Path]::PathSeparator

# Separator between directories in a path: '\' on Windows, '/' everywhere else
$global:dirSep = [System.IO.Path]::DirectorySeparatorChar

# Returns $true when running elevated (Administrator on Windows, uid 0 on Unix)
function global:Test-IsElevated
{
    if ($global:isWindowsPlatform)
    {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal] $identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    return ((id -u) -eq 0)
}

# Guard for functions that wrap Windows-only tooling. Prints why the command is
# unavailable and returns $false so the caller can bail out early.
function global:Test-WindowsOnly([string] $feature)
{
    if ($global:isWindowsPlatform)
    {
        return $true
    }

    Write-Host -ForegroundColor Yellow "$feature is only available on Windows."
    return $false
}

# Converts a filesystem path into a file:// URL that git accepts on any platform.
# Windows paths become file:///D:/foo, Unix paths become file:///home/foo.
# Note the [System.Uri]::new() call: the [System.Uri] cast builds a *relative*
# Uri from a Unix path, whose AbsoluteUri is unusable.
function global:ConvertTo-FileUrl([string] $path)
{
    return ([System.Uri]::new((Resolve-Path $path).Path)).AbsoluteUri
}
