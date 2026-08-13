# Finds the most deeply nested subfolder under a path

function global:max_depth($path)
{
    $max = -1
    $deepestSubfolder = ""

    Get-ChildItem -Recurse $path | ForEach-Object {
        $relative = Resolve-Path $_.FullName -Relative
        $cur = (($relative.ToCharArray() | Where-Object { $_ -eq $global:dirSep } | Measure-Object).Count)

        if($cur -gt $max)
        {
            $max = $cur
            $deepestSubfolder = $relative
        }
    }

    Write-Host "Deepest subfolder is $max levels deep, and is in subfolder $deepestSubfolder"
}
