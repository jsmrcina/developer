# Summarizes channel/bitrate/sample rate across a set of audio files

function global:dumpaudioinfo([string]$path)
{
    if (-not (checktool "ffprobe"))
    {
        return
    }

    $fileList = @()
    if($path.Contains("*"))
    {
        Get-ChildItem -File -Recurse $path | ForEach-Object { $fileList += $_ }
    }
    else
    {
        $fileList += $path
    }

    if($fileList.Count -eq 0)
    {
        Write-Host -ForegroundColor Yellow "No files matched '$path'"
        return
    }

    $summary = @{}
    $numRead = 0
    foreach($item in $fileList)
    {
        $percentComplete = [int] (($numRead / $fileList.Count) * 100)
        Write-Progress -Activity "Reading files" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete

        $output = ffprobe -v error -select_streams a:0 -show_entries stream=channels,bit_rate,sample_rate -of json $item | ConvertFrom-Json

        $channels = $output.streams[0].channels
        $bitrate = $output.streams[0].bit_rate
        $sampleRate = $output.streams[0].sample_rate
        $key = "$channels|$bitrate|$sampleRate"

        if(-not $summary.ContainsKey($key))
        {
            $summary[$key] = [PSCustomObject]@{
                channels   = $channels
                bitrate    = $bitrate
                sampleRate = $sampleRate
                files = 0
            }
        }

        $summary[$key].Files++
        $numRead++
    }

    Write-Progress -Activity "Reading files" -Completed
    $summary.Values | Sort-Object Files -Descending | Format-Table -AutoSize
}
