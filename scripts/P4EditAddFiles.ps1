$files = @($input)

foreach ($file in $files)
{
    $filePath = Resolve-Path $file
    $result = p4 fstat "$filePath" 2>&1
    Write-Host -ForegroundColor Cyan $filePath

    if ($result -match "\.\.\. depotFile")
    {
        p4 edit "$filePath"
        Write-Host -ForegroundColor Green "Edited $filePath"
    }
    else
    {
        p4 add "$filePath"
        Write-Host -ForegroundColor Magenta "Added $filePath"
    }
}

Write-Host "`nDone. Press Enter to exit..."
[void][System.Console]::ReadLine()