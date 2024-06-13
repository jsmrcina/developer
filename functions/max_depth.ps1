# Creates a branch locally and remotely

function global:max_depth($path)
{
    $max = -1
    $deepestSubfolder = ""
    Get-ChildItem -Recurse $path | % {
        $path = Resolve-Path $_.FullName -Relative
        $cur = (($path.ToCharArray() | Where-Object { $_ -eq '\' } | Measure-Object).Count)

        if($cur -gt $max)
        {
            $max = $cur
            $deepestSubfolder = $path
        }
    }

    Write-Host "Deepest subfolder is $max levels deep, and is in subfolder $deepestSubfolder"
}