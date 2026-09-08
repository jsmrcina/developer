param(
    # Directory holding the .mp4 files to convert. Defaults to the current
    # directory so the script can be dropped into a folder and run as-is.
    [string]$Path = ".",

    # Where the converted files land. Defaults to an "out" folder under $Path.
    [string]$OutputPath,

    [bool]$makeSmall = $false,

    # nvenc_av1 = fastest at equal-or-better quality on this machine's RTX 5080.
    # Swap to nvenc_h265 (with -Quality 24) if a target device can't decode AV1,
    # or to x264 to fall back to the stock preset encoder.
    [string]$Encoder = "nvenc_av1",

    [int]$Quality = 28
)

$videoDir = (Resolve-Path -Path $Path -ErrorAction Stop).Path

if (-not (Test-Path -Path $videoDir -PathType Container))
{
    throw "Not a directory: $videoDir"
}

if (-not $OutputPath)
{
    $OutputPath = Join-Path -Path $videoDir "out"
}

$files = @(Get-ChildItem (Join-Path -Path $videoDir "*.mp4") -File)
if ($files.Count -eq 0)
{
    Write-Host "No .mp4 files found in $videoDir"
    return
}

New-Item $OutputPath -ItemType Directory -ErrorAction Ignore | Out-Null
$outDir = (Resolve-Path -Path $OutputPath).Path

$counter = 0
foreach ($file in $files)
{
    $counter++
    $inFile = $file.FullName

    $noExt = Split-Path -LeafBase $file
    $fileName = ($noExt + "_out.mp4")
    $outFile = Join-Path -Path $outDir $fileName

    Write-Progress -Activity "Converting videos" `
                   -Status "Processing $($file.Name) ($counter of $($files.Count))" `
                   -PercentComplete (($counter / $files.Count) * 100)

    # NVDEC offloads the HEVC decode of these phone clips to the GPU. It is the
    # bigger win of the two: this pipeline is decode-bound, not encode-bound.
    $common = @("--enable-hw-decoding", "nvdec", "--input", $inFile, "--output", $outFile)

    if ($makeSmall)
    {
        # "Social" is a two-pass *average bitrate* preset -- that is what holds the
        # 25 MB budget -- so leave its encoder and rate control alone.
        HandBrakeCLI -Z "Web/Social 25 MB 30 Seconds 1080p60" @common
    }
    elseif ($Encoder -eq "x264")
    {
        HandBrakeCLI -Z "Web/Creator 1440p60 2.5K" @common
    }
    else
    {
        # "Creator" is constant-quality RF 21 (its VideoAvgBitrate=12000 is inert),
        # so match it with an RF, not a bitrate. --encopts clears the preset's
        # x264-only options, which mean nothing to NVENC.
        HandBrakeCLI -Z "Web/Creator 1440p60 2.5K" -e $Encoder --encopts "" -q $Quality @common
    }
}
