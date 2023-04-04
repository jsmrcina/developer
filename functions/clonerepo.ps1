function global:clonerepo([string]$repourl)
{
    $parts = $repourl.Split("/")
    $final = $parts[$parts.Length - 1]
    $parts = $final.Split(".")
    $folderName = $parts[0]
    Write-Host $folderName

    if((Test-Path $folderName) -eq $true)
    {
        Write-Error "Folder '$folderName' already exists, exiting"
    }
    else
    {
        Write-Host "Cloning '$repourl' into '$folderName'"
        git clone $repourl $folderName
    }  
}