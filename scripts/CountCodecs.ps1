param(
    [string]$Path = ".",
    [bool]$IncludeFileNames = $false
)

$videoExtensions = @(".mp4", ".mkv", ".mov", ".avi", ".webm")
$files = Get-ChildItem -Path $Path -Recurse -File |
    Where-Object {
        $videoExtensions -contains $_.Extension.ToLower()
    }

$total = $files.Count
$counter = 0
$results = @()

foreach ($file in $files)
{
    $counter++

    Write-Progress -Activity "Scanning video files" `
                   -Status "Processing $($file.Name) ($counter of $total)" `
                   -PercentComplete (($counter / $total) * 100)

    $codec = & ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$($file.FullName)"

    $results += [PSCustomObject]@{
        FileName = $file.FullName
        Codec = $codec
    }
}

$results |
Group-Object -Property Codec |
Sort-Object Count -Descending |
ForEach-Object {
    Write-Host "`nCodec: $($_.Name) — $($_.Count) file(s)" -ForegroundColor Cyan

    if($IncludeFileNames)
    {
        $_.Group | ForEach-Object { Write-Host $_.FileName }
    }
}
