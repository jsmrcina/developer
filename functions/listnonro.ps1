
function global:listnonro()
{
    $extensions = @(".java", ".xml", ".gradle")
    $ignoreDirs = @("build", ".idea")
    Get-ChildItem -Path "." -File -Recurse | % { 
        $path = $_.FullName

        $hasExt = $extensions -contains $_.Extension
        $ro = $_.IsReadOnly
        $ignored = $false
        
        foreach($ignore in $ignoreDirs)
        {
            if($path.Contains($ignore))
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