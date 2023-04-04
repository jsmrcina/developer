function global:checkingit([string]$owner)
{
    gci | ForEach-Object {
        if(-not (Test-Path "$_\.git"))
        {
            Write-Host "$_ is not in Git"
        }
        else
        {
            foreach($line in Get-Content "$_\.git\config")
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

            return
        }
    }
}
