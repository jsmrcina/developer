param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [string[]]$Platform,

    [string[]]$Config,

    [string]$Target,

    [bool]$IncludeCl = $true,

    [bool]$ZipOutput = $true
)

$currentDir = Get-Location
$platformsPath = Join-Path $currentDir "platforms.txt"
$configsPath = Join-Path $currentDir "config.txt"

if (-not (Test-Path $ProjectPath)) 
{
    Write-Error "Project file does not exist: $ProjectPath"
    exit 1
}

$projectJson = Get-Content $ProjectPath | ConvertFrom-Json
$engineAssociation = $projectJson.EngineAssociation

$registryPath = "HKCU:\Software\Epic Games\Unreal Engine\Builds"
$enginePath = Get-ItemProperty -Path $registryPath | Select-Object -ExpandProperty $engineAssociation

if (-not (Test-Path $enginePath)) 
{
    Write-Error "Unable to locate Unreal Engine installation for association ID: $engineAssociation"
    exit 1
}

$uatPath = Join-Path $enginePath "Engine\Build\BatchFiles\RunUAT.bat"

if (-not (Test-Path $uatPath)) 
{
    Write-Error "RunUAT.bat not found at expected location: $uatPath"
    exit 1
}

if ($IncludeCl)
{
    function Find-P4Exe
    {
        $registryPaths = @(
            "HKLM:\SOFTWARE\Perforce",
            "HKLM:\SOFTWARE\WOW6432Node\Perforce"
        )

        foreach ($regPath in $registryPaths)
        {
            if (Test-Path $regPath)
            {
                $props = Get-ItemProperty -Path $regPath
                if ($props.P4INSTROOT)
                {
                    $candidate = Join-Path $props.P4INSTROOT "p4.exe"
                    if (Test-Path $candidate)
                    {
                        return $candidate
                    }
                }
            }
        }

        $fallback = Get-Command "p4.exe" -ErrorAction SilentlyContinue
        if ($fallback) { return $fallback.Path }

        return $null
    }

    $p4Path = Find-P4Exe

    if (-not $p4Path)
    {
        Write-Warning "p4.exe not found. Falling back to CL=NA"
        $p4Change = "NA"
    }
    else
    {
        & $p4Path sync
        & $p4Path resolve

        $p4Change = & $p4Path changes -m1 "//...#have" 2>$null | ForEach-Object {
            if ($_ -match '^Change\s+(\d+)\s') { return $matches[1] }
        } | Select-Object -First 1

        if (-not $p4Change)
        {
            Write-Warning "Could not determine synced Perforce changelist. Using NA."
            $p4Change = "NA"
        }
    }
}

$timestamp = Get-Date -Format "yy.MM.dd.HHmm"

if (-not $Platform)
{
    if (-not (Test-Path $platformsPath)) 
    {
        Write-Error "Missing platforms.txt and no -Platform argument specified."
        exit 1
    }

    $Platform = Get-Content $platformsPath | Where-Object { $_.Trim() -ne "" }
}

if (-not $Config)
{
    if (-not (Test-Path $configsPath)) 
    {
        Write-Error "Missing config.txt and no -Config argument specified."
        exit 1
    }

    $Config = Get-Content $configsPath | Where-Object { $_.Trim() -ne "" }
}

foreach ($platform in $Platform)
{
    foreach ($config in $Config)
    {
        $platform = $platform.Trim()
        $config = $config.Trim()

        if ($IncludeCl -and $p4Change)
        {
            $outputDir = Join-Path -Path $OutputRoot -ChildPath "$platform\$timestamp-$p4Change-$config"
        }
        else
        {
            $outputDir = Join-Path -Path $OutputRoot -ChildPath "$platform\$timestamp-$config"
        }

        Write-Host "About to start building $ProjectPath, for platform $platform, with config $config, and output to $outputDir" -ForegroundColor Green

        $uatArgs = @(
            "-project=${ProjectPath}"
            "-noP4"
            "-platform=${platform}"
            "-clientconfig=${config}"
            "-serverconfig=${config}"
            "-cook"
            "-allmaps"
            "-build"
            "-stage"
            "-pak"
            "-package"
            "-archive"
            "-archivedirectory=${outputDir}"
        )

        if ($Target)
        {
            $uatArgs += "-target=${Target}"
            $uatArgs += "-targetplatform=${platform}"
        }

        & $uatPath BuildCookRun @uatArgs
    }
}
