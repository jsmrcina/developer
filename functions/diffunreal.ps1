# Squashes the current branch into a single commit. Useful for squash merge based repositories before you rebase onto main
function global:diffunreal([string] $UnrealPath, [string] $ProjectPath, [string]$FilePath, [string]$FirstCommitIsh, [string]$SecondCommitIsh)
{

if (-not (Get-Command "git.exe" -ErrorAction SilentlyContinue))
{
    Write-Error "Cannot find git.exe"
}

$output = (git status --porcelain)
if ($LASTEXITCODE -ne 0)
{
    Write-Error "'git status' returned an error. Is this a git repository?"
    git status
    return;
}
elseif (-not ([string]::IsNullOrEmpty($output)))
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

if ([string]::IsNullOrEmpty($UnrealPath))
{
    $UnrealPath = $global:developerUnrealPath
    Write-Host ("No Unreal path specified, falling back to value of global:developerUnrealPath: {0}" -f $global:developerUnrealPath)
}
else
{
    Write-Host ("Using Unreal path: {0}" -f $UnrealPath)
}

if ([string]::IsNullOrEmpty($FirstCommitIsh))
{
    $FirstHash = git merge-base $global:officialBranch HEAD
    Write-Host ("Found merge-base with {0} branch at hash {1}" -f $global:officialBranch,$FirstHash)
}
else
{
    $FirstHash = $FirstCommitIsh
    Write-Host ("Using user-supplied first hash: {0}" -f $FirstHash)
}

if ([string]::IsNullOrEmpty($SecondCommitIsh))
{
    $SecondHash = "HEAD"
    Write-Host "No second hash specified, defaulting to HEAD"
}
else
{
    $SecondHash = $SecondCommitIsh
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
    Start-Process -Wait -FilePath $UnrealPath -ArgumentList $Arguments
}
catch
{
    Write-Error "An error occurred: $_"
}

}