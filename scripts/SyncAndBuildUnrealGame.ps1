param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [string[]]$Platforms,

    [string[]]$Configs,

    [string]$Target,

    [bool]$IncludeCl = $true,

    [bool]$ZipOutput = $true,

    [switch]$Distribution = $false,

    [string]$ArchiveDirectory,

    [hashtable]$PlatformsMapping
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

if ($ArchiveDirectory -and -not $ZipOutput)
{
    Write-Error "-ArchiveDirectory specified but -ZipOutput is disabled. This is not allowed."
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

if (-not $Platforms)
{
    if (-not (Test-Path $platformsPath)) 
    {
        Write-Error "Missing platforms.txt and no -Platform argument specified."
        exit 1
    }

    $Platforms = Get-Content $platformsPath | Where-Object { $_.Trim() -ne "" }
}

if (-not $Configs)
{
    if (-not (Test-Path $configsPath)) 
    {
        Write-Error "Missing config.txt and no -Config argument specified."
        exit 1
    }

    $Configs = Get-Content $configsPath | Where-Object { $_.Trim() -ne "" }
}

$results = @()
foreach ($platform in $Platforms)
{
    foreach ($config in $Configs)
    {

        $timestamp = Get-Date -Format "yy.MM.dd.HHmm"
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

        if ($Distribution)
        {
            $uatArgs += "-distribution"
        }

        $str = "$uatPath BuildCookRun " + ($uatArgs -join ' ')
        Write-Host -ForegroundColor Green $str

        # & $uatPath BuildCookRun @uatArgs

        if ($ZipOutput)
        {
            $zipExe = Get-Command "7z.exe" -ErrorAction SilentlyContinue

            if (-not $zipExe)
            {
                $knownPaths = @(
                    "${env:ProgramFiles}\7-Zip\7z.exe",
                    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
                )

                foreach ($path in $knownPaths)
                {
                    if (Test-Path $path)
                    {
                        $zipExe = $path
                    }
                }
            }

            if (-not $zipExe)
            {
                Write-Warning "7z.exe not found. Skipping zip step for $outputDir."
            }
            else
            {
                $zipName = Join-Path -Path (Split-Path -Path $outputDir -Parent) -ChildPath "$([System.IO.Path]::GetFileName($outputDir)).7z"
                Write-Host "Zipping $outputDir to $zipName" -ForegroundColor Cyan

                & $zipExe a "-t7z" "$zipName" "$outputDir\*" | Out-Null

                if (Test-Path $zipName)
                {
                    $results += $zipName
                    Write-Host "Created archive: $zipName" -ForegroundColor Green
                }
                else
                {
                    Write-Warning "Failed to create archive: $zipName"
                }
            }
        }
    }
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
foreach($result in $results)
{
    Write-Host ("Generated: " + $result) -ForegroundColor Cyan
}

if ($ZipOutput -and $ArchiveDirectory)
{
    $now = Get-Date -Format "yyyy-MM-dd"
    $clLabel = if ($IncludeCl -and $p4Change) { "$p4Change" } else { "NA" }

    foreach ($zipPath in $results)
    {
        $zipFileName = [System.IO.Path]::GetFileName($zipPath)
        $zipDir = [System.IO.Path]::GetDirectoryName($zipPath)
        $platformName = Split-Path -Path $zipDir -Leaf

        $mappedName = if ($PlatformsMapping.ContainsKey($platformName)) {
            $PlatformsMapping[$platformName]
        } else {
            $platformName
        }

        $destDir = Join-Path $ArchiveDirectory (Join-Path $mappedName "$now-$clLabel")

        if (-not (Test-Path $destDir))
        {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }

        $destPath = Join-Path $destDir $zipFileName

        Copy-Item -Path $zipPath -Destination $destPath -Force

        Write-Host "Archived $zipFileName to $destPath" -ForegroundColor Yellow
    }
}
