param(
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$lines = git lfs push --dry-run $Remote $Branch
$pushEntries = @()
foreach ($line in $lines)
{
    if ($line -match "^push\s+([a-f0-9]{64})\s+=>\s+(.+)$")
    {
        $pushEntries += [PSCustomObject]@{
            Sha  = $matches[1]
            Path = $matches[2]
        }
    }
}

$totalBytes = 0
$currentIndex = 0
$totalFiles = $pushEntries.Count

foreach ($entry in $pushEntries)
{
    $currentIndex++

    Write-Progress -Activity "Estimating LFS Push Size" `
                   -Status "Processing file $currentIndex of $totalFiles" `
                   -PercentComplete (($currentIndex / $totalFiles) * 100)

    if (Test-Path $entry.Path)
    {
        $fileInfo = Get-Item $entry.Path
        $totalBytes += $fileInfo.Length
        Write-Output ($fileInfo.Length.ToString() + " " + $entry.Sha + " " + $entry.Path)
    }
    else
    {
        Write-Warning "File not found: $($entry.Path)"
    }
}

Write-Progress -Activity "Estimating LFS Push Size" -Completed

$totalMB = [math]::Round($totalBytes / 1MB, 2)
Write-Output "Estimated LFS push size: $totalMB MB"
