function global:p4_describe($numChanges, $userName = "jsmrcina")
{
    $changes = p4 changes -m $numChanges -u $userName | % {
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