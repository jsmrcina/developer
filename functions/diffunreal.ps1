# Squashes the current branch into a single commit. Useful for squash merge based repositories before you rebase onto main
function global:diffunreal([string] $ProjectPath, [string]$FilePath, [string]$FirstCommitIsh, [string]$SecondCommitIsh)
{

if ($null -ne (git status --porcelain) -and (git status --porcelain) -ne '')
{
    Write-Error "There are uncommitted changes, aborting. Output of 'git status':"
    git status
    return;
}
else
{
    Write-Host "No uncommitted changes... continuing"
}

Write-Host "Making sure we have up-to-date commits via 'git fetch'..."
git fetch

$FirstHash = $FirstCommitIsh
if ($null -eq $FirstCommitIsh -or '' -eq $FirstCommitIsh)
{
    $FirstHash = git merge-base $global:officialBranch HEAD
    Write-Host ("Found merge-base with {0} branch at hash {1}" -f $global:officialBranch,$FirstHash)
}
else
{
    Write-Host ("Using user-supplied first hash: {0}" -f $FirstHash)
}

$SecondHash = $SecondCommitIsh
if ($null -eq $SecondCommitIsh -or '' -eq $SecondCommitIsh)
{
    $SecondHash = "HEAD"
    Write-Host "No second hash specified, defaulting to HEAD"
}
else
{
    Write-Host ("Using user-supplied second hash: {0}" -f $SecondHash)
}

try
{
    # Fully qualify our paths
    $ProjectPath = (gci $ProjectPath)[0].FullName
    $FilePath = (gci $FilePath)[0].FullName

    git checkout $FirstHash -- $FilePath
    $FirstFilePath = New-TemporaryFile
    Copy-Item $FilePath $FirstFilePath

    git checkout $SecondHash -- $FilePath
    $SecondFilePath = New-TemporaryFile
    Copy-Item $FilePath $SecondFilePath

    Write-Host ("Performing diff between hash {0} and {1}" -f $FirstHash, $SecondHash) -ForegroundColor Green 

    # Step 3: Call UnrealEditor with the diff option to compare the old file and the checked out file
    $Arguments = @($ProjectPath, "-diff", $FirstFilePath, $SecondFilePath)
    Start-Process -Wait -FilePath "F:\git\ue4.27-plus\Engine\Binaries\Win64\UE4Editor.exe" -ArgumentList $Arguments
}
catch
{
    Write-Error "An error occurred: $_"
}

}