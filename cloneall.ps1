# Make sure you have ghcli installed: https://cli.github.com/ and have run "gh auth login" once

function global:cloneall()
{
    gh auth status

    if($LASTEXITCODE -ne 0)
    {
        Write-Error "You are not logged into GitHub CLI, please run 'gh auth login' before running this script"
        return
    }

    gh repo list jsmrcina --limit 999 --json name --jq ".[]|.name" |
        ForEach-Object {
            if(Test-Path "$global:gitFolderPath\$_")
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