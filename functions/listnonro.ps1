
function global:listnonro()
{
    $extensions = @(".java", ".xml", ".gradle")
    $ignoreDirs = @("build", ".idea")

    Get-ChildItem -Path "." -File -Recurse | ForEach-Object {
        $path = $_.FullName

        $hasExt = $extensions -contains $_.Extension
        $ro = $_.IsReadOnly
        $ignored = $false

        foreach($ignore in $ignoreDirs)
        {
            # Match a whole path segment rather than a bare substring
            if($path -like "*$global:dirSep$ignore$global:dirSep*")
            {
                $ignored = $true
            }
        }

        if(($hasExt) -and (-not $ro) -and (-not $ignored))
        {
            Write-Host $path
        }
    }
}
