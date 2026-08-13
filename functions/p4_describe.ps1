function global:p4_describe($numChanges, $userName = $global:p4User)
{
    if (-not (checktool "p4"))
    {
        return
    }

    if ([string]::IsNullOrWhiteSpace($userName))
    {
        Write-Error "No user specified and no 'p4User' set in your config file"
        return
    }

    $changes = p4 changes -m $numChanges -u $userName | ForEach-Object {
        ($_ -split ' ')[1]
    }

    Write-Output ('-' * 120)

    foreach ($Change in $changes)
    {
        $fullDescription = p4 describe $change
        $lines = $fullDescription -split "`n"

        $descriptionLines = @()
        foreach ($line in $lines)
        {
            if ($line.StartsWith('Affected files'))
            {
                break
            }
            elseif([String]::IsNullOrEmpty($line))
            {
                # Ignore
            }
            else
            {
                $descriptionLines += $line
            }
        }

        Write-Output $descriptionLines
        Write-Output ('-' * 120)
    }
}
