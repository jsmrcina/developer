# Checks whether a specific repository is using Git

function global:checkingit([string]$owner)
{
    Get-ChildItem -Directory | ForEach-Object {
        $gitDir = Join-Path $_.FullName ".git"

        if(-not (Test-Path $gitDir))
        {
            Write-Host "$_ is not in Git"
        }
        else
        {
            foreach($line in Get-Content (Join-Path $gitDir "config"))
            {
                if($line.Trim().StartsWith("url = "))
                {
                    # HTTPS
                    if($line.Contains("https"))
                    {
                        if(-not ($line.Contains($owner)))
                        {
                            Write-Host "$_ is not owned by $owner"
                        }
                    }
                    # SSH
                    elseif($line.Contains("git@github.com"))
                    {
                        if(-not ($line.Contains($owner)))
                        {
                            Write-Host "$_ is not owned by $owner"
                        }
                    }
                }
            }
        }
    }
}
