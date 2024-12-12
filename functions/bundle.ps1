# Bundles a repo including LFS content per https://stackoverflow.com/questions/52111702/git-bundle-with-lfs
# To extract, into a repository, you need to unzip to a folder and then clone from that folder:
# git clone file:///D:/libve-extract libve
# TODO: Include PR descriptions in the bundle
# TODO: Don't install LFS if there are no LFS objects

function global:bundle([string]$repourl)
{
    $parts = $repourl.Split("/")
    $final = $parts[$parts.Length - 1]
    $parts = $final.Split(".")
    $projectName = $parts[0]
    $mirrorName = ($projectName + "-bundle-clone")

    if((Test-Path $mirrorName) -eq $true)
    {
        Write-Error "Folder '$mirrorName' already exists, exiting"
        return
    }
    else
    {
        Write-Host "Cloning '$repourl' into '$mirrorName'"
        git clone $repourl $mirrorName
    }

    cd $mirrorName
    git fetch --all
    git fetch --tags
    git lfs install
    git lfs fetch --all

    cd ..
    $bundleFolderName = ($projectName + "-bundle")
    mkdir $bundleFolderName
    cd $bundleFolderName
    git init --bare
    $barePath = (Get-Location).Path.Replace("\", "/")
    $fileUrl = "file:///$barePath"

    cd ..
    cd $mirrorName

    git config lfs.url $fileUrl
    git config lfs.allowincompletepush true
    git config lfs.locksverify false

    git remote add bare $fileUrl
    git push --mirror bare
    git lfs push --all bare

    cd ..
    $tarName = "$projectName.tar.gz"
    tar -czvf $tarName $bundleFolderName

    Remove-Item -Force -Recurse $mirrorName
    Remove-Item -Force -Recurse $bundleFolderName

    Write-Host -ForegroundColor Green "Output is in $tarName"
}