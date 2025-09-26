param(
    [Parameter(Mandatory = $true)]
    [string]$Folder,

    [int]$TopN,

    [string[]]$ExcludeExtensions,

    [string[]]$IgnorePathContains
)

$normalizedExcludes = @()
if ($ExcludeExtensions)
{
    $normalizedExcludes = $ExcludeExtensions | ForEach-Object { $_.ToLower() }
}

$results = Get-ChildItem -Path $Folder -Recurse -File |
    Where-Object {
        $ext = if ($_.Extension) { $_.Extension.ToLower() } else { "<no extension>" }
        if ($normalizedExcludes -contains $ext)
        {
            return $false
        }

        if ($IgnorePathContains)
        {
            foreach ($pattern in $IgnorePathContains)
            {
                if ($_.FullName -like "*$pattern*")
                {
                    return $false
                }
            }
        }

        return $true
    } |
    Group-Object {
        if ($_.Extension)
        {
            $_.Extension.ToLower()
        }
        else
        {
            "<no extension>"
        }
    } |
    ForEach-Object {
        $count = $_.Group.Count
        $sum   = ($_.Group | Measure-Object Length -Sum).Sum
        [PSCustomObject]@{
            Extension   = $_.Name
            FileCount   = $count
            TotalMB     = '{0:N2}' -f ($sum / 1MB)
            AverageKB   = '{0:N2}' -f (($sum / $count) / 1KB)
        }
    } |
    Sort-Object {[double]$_.TotalMB} -Descending

if ($TopN -gt 0)
{
    $results = $results | Select-Object -First $TopN
}

$results | Format-Table -AutoSize
