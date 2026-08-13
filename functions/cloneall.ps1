# Clones all repositories for a specific user into the current folder
# Make sure you have ghcli installed: https://cli.github.com/ and have run "gh auth login" once

function global:cloneall([string]$owner = $global:githubUser)
{
    if (-not (checktool "gh"))
    {
        Write-Host "Go to https://cli.github.com/ to download the GitHub CLI"
        return
    }

    if ([string]::IsNullOrWhiteSpace($owner))
    {
        Write-Error "No owner specified and no 'githubUser' set in your config file"
        return
    }

    gh auth status

    if($LASTEXITCODE -ne 0)
    {
        Write-Error "You are not logged into GitHub CLI, please run 'gh auth login' before running this script"
        return
    }

    gh repo list $owner --limit 999 --json name --jq ".[]|.name" |
        ForEach-Object {
            if(Test-Path (Join-Path $global:gitFolderPath $_))
            {
                Write-Host "$_ is already cloned" -ForegroundColor Blue
            }
            else
            {
                Write-Host "$_ is not cloned yet, cloning..." -ForegroundColor Yellow
                gh repo clone $_
            }
        }
}
