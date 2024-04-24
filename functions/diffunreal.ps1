<#
    .SYNOPSIS
    Allows diffing two unreal assets using the unreal editor diff and a set of git commit-ish's.

    .PARAMETER UnrealPath
    Specifies the fully qualified path to the Unreal editor executable. If one is not specified, will default to the value of $global:developerUnrealPath

    .PARAMETER ProjectPath
    Specifies the path to the Unreal uproject that these assets belong to.

    .PARAMETER FilePath
    Specifies the path to the file that we want to diff.

    .PARAMETER FirstCommitIsh
    Specifies a commitish (SHA hash, etc.) to start comparing from. If one is not specified, the script will attempt to find a merge base with whatever branch name is set
    in $global:officialBranch.

    .PARAMETER FirstCommitIsh
    Specifies a commitish (SHA hash, etc.) to end comparing at. If one is not specified, the script will assume you want to compare with HEAD.

    .PARAMETER Verbose
    Dump verbose output during execution

    .INPUTS
    None.

    .OUTPUTS
    None.
#>

function global:diffunreal {
    param(
        [Parameter(Mandatory=$false)]
        [string] $UnrealPath,
        [Parameter(Mandatory=$false)]
        [string] $ProjectPath,
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [Parameter(Mandatory=$false)]
        [string]$FirstCommitIsh,
        [Parameter(Mandatory=$false)]
        [string]$SecondCommitIsh,
        [Parameter(Mandatory=$false)]
        [bool]$IsVerbose = $true
    )

# Internal function for using git low level commands to query the contents of a file at a specific hash
function GetFileContentsForHash {
    param(
        [Parameter(Mandatory=$true)]
        [string] $InternalFilePath,
        [Parameter(Mandatory=$true)]
        [string] $InternalCommitIsh,
        [Parameter(Mandatory=$true)]
        [string] $InternalTempFilePath,
        [Parameter(Mandatory=$true)]
        [bool] $InternalVerbose)

    $ObjId = (git ls-tree $InternalCommitIsh $InternalFilePath).Split(" ")[2].Split("`t")[0]
    $FilePointerInfo = (git cat-file -p $objId)

    if($InternalVerbose -eq $true)
    {
        Write-Host
        $DebugOutput = 'For file: {0}, and commit: {1}, output to: {2}, found object id: {3}' -f $InternalFilePath, $InternalCommitIsh, $InternalTempFilePath, $ObjId
        Write-Host -ForegroundColor Blue $DebugOutput
    }

    # Verify this is a git lfs file pointer (as all unreal assets should hopefully be)
    if(-not $FilePointerInfo[0].Equals("version https://git-lfs.github.com/spec/v1"))
    {
        return $false
    }

    #
    # Download the actual file contents using git lfs smudge. We have to do some
    # additional work here as the output of git lfs smudge is binary
    # and powershell will try to mangle it into an encoding if we're not careful
    # about how we pipe it to our temporary file
    #
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.FileName = "git"
    $ProcessStartInfo.WorkingDirectory = (Get-Location).Path
    $ProcessStartInfo.Arguments = "lfs smudge"
    $ProcessStartInfo.UseShellExecute = $false
    $ProcessStartInfo.RedirectStandardInput = $true
    $ProcessStartInfo.RedirectStandardOutput = $true
    $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)
    
    foreach($s in $FilePointerInfo)
    {
        $Process.StandardInput.WriteLine($s)
    }
    
    # Terminate the pointer file
    $Process.StandardInput.WriteLine()

    # Write the output to our temporary file
    $outputFileStream = [System.IO.File]::OpenWrite($InternalTempFilePath)
    $buffer = New-Object byte[] 4096
    while ($true)
    {
        $bytesRead = $Process.StandardOutput.BaseStream.Read($buffer, 0, $buffer.Length)
        if ($bytesRead -gt 0)
        {
            $outputFileStream.Write($buffer, 0, $bytesRead)
        }
        else
        {    
            break
        }
    }
    $outputFileStream.Close()
    $Process.WaitForExit()

    return $true
}

Write-Host
Set-StrictMode -Version 3.0

# Validate git exists and we are in a git repo
if (-not (Get-Command "git.exe" -ErrorAction SilentlyContinue))
{
    Write-Error "Cannot find git.exe"
}

$output = (git status --porcelain)
if ($LASTEXITCODE -ne 0)
{
    Write-Error "'git status' returned an error. Is this a git repository?"
    git status
    $LASTEXITCODE = 1
    return
}

# Validate file we are comparing exists
if (-not (Test-Path -Path $FilePath))
{
    Write-Error ("Cannot find file to compare at path: {0}. Exiting..." -f $FilePath)
    $LASTEXITCODE = 1
    return
}

$FilePath = (Get-ChildItem $FilePath)[0].FullName
Write-Host ("Comparing file: {0}" -f $FilePath)
Write-Host

# Validate Unreal Editor is found
if ([string]::IsNullOrEmpty($UnrealPath))
{
    $UnrealPath = $global:developerUnrealPath
    Write-Host ("No Unreal path specified, falling back to value of global:developerUnrealPath: {0}" -f $global:developerUnrealPath)
}
else
{
    Write-Host ("Using Unreal path: {0}" -f $UnrealPath)
}

if (-not (Test-Path -Path $UnrealPath))
{
    Write-Error ("Cannot find Unreal Editor at path: {0}. Exiting..." -f $UnrealPath)
    $LASTEXITCODE = 1
    return
}

Write-Host

# Validate uproject exists
if ([string]::IsNullOrEmpty($ProjectPath))
{
    $UProjectFilesInDirectory = (Get-ChildItem *.uproject)
    $Measured = ($UProjectFilesInDirectory | Measure-Object)
    if($Measured.Count -eq 1)
    {
        $ProjectPath = $UProjectFilesInDirectory[0].FullName
        Write-Host ("No uproject path specified, found a single uproject in the current directoy, using it: {0}" -f $ProjectPath)
    }
    else
    {
        Write-Error "No uproject path specified and no (or more than one) uproject file found in the current directory. Exiting..."
        $LASTEXITCODE = 1
        return
    }
}
else
{
    if (-not (Test-Path -Path $ProjectPath))
    {
        Write-Error ("Cannot find uproject at path: {0}. Exiting..." -f $ProjectPath)
        $LASTEXITCODE = 1
        return
    }

    $ProjectPath = (Get-ChildItem $ProjectPath)[0].FullName
    Write-Host ("Using user-supplied uproject: {0}" -f $ProjectPath)
}

Write-Host

# Validate user supplied a valid first commit hash or we can find a merge-base
if ([string]::IsNullOrEmpty($FirstCommitIsh))
{
    Write-Host ("User did not supply a first commitish. Attempting to find a merge base with branch {0}" -f $global:officialBranch)
    $FirstHash = git merge-base $global:officialBranch HEAD

    if($LASTEXITCODE -ne 0)
    {
        $ErrorOutput = "Command 'git merge-base {0} HEAD' failed with error {1}. Is variable global:officialBranch set? Exiting..." -f $global:officialBranch,$LASTEXITCODE
        Write-Error $ErrorOutput
        $LASTEXITCODE = 1
        return
    }

    Write-Host ("Found merge-base with {0} branch at hash {1}" -f $global:officialBranch, $FirstHash)
    Write-Host ("Checking to see if file was edited at hash {0}" -f $FirstHash)
    $Result = (git ls-tree $InternalCommitIsh $InternalFilePath)
    if($null -eq $Result)
    {
        Write-Warning ("File was not edited at hash {0}, will try to find earliest edit hash between merge-base and second proivded hash")
        $SearchForFirstHash = $true
    }
    else
    {
        Write-Host ("File was edited at hash {0}, using that as our compare hash" -f $FirstHash)
    }
}
else
{
    $FirstHash = $FirstCommitIsh
    Write-Host ("Using user-supplied first hash: {0}" -f $FirstHash)
}

Write-Host

# Validate user supplied a valid second commit hash, or we default to HEAD 
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

if ($SearchForFirstHash)
{
    Write-Error "The script currently requires that both hashes have the file edited... please choose a first hash that contains edits to the file"
    $LASTEXITCODE = 1
    return

    # TODO: Work on this more
    #$DebugOutput = ("Searching for oldest edited hash for file {0} between hashes {1} and {2}" -f $FilePath, $FirstHash, $SecondHash)
    #Write-Host $DebugOutput
    #git rev-list $FirstHash $SecondHash $FilePath
}

try
{
    $FirstFilePath = New-TemporaryFile
    $GotFirstFile = GetFileContentsForHash $FilePath $FirstHash $FirstFilePath $IsVerbose
    if(-not $GotFirstFile)
    {
        Write-Error "Was not able to query first file, the file was not a valid Git LFS pointer"
        $LASTEXITCODE = 1
        return
    }

    $SecondFilePath = New-TemporaryFile
    $GotSecondFile = GetFileContentsForHash $FilePath $SecondHash $SecondFilePath $IsVerbose
    if(-not $GotSecondFile)
    {
        Write-Error "Was not able to query first file, the file was not a valid Git LFS pointer"
        $LASTEXITCODE = 1
        return
    }

    Write-Host
    Write-Host ("Performing diff between hash {0} and {1}" -f $FirstHash, $SecondHash) -ForegroundColor Green 

    # Call UnrealEditor with the diff option to compare the old file and the checked out file
    $Arguments = @($ProjectPath, "-diff", $FirstFilePath, $SecondFilePath)
    Start-Process -FilePath $UnrealPath -ArgumentList $Arguments

    # Success!
    $LASTEXITCODE = 0
    return
}
catch
{
    Write-Error "An error occurred: $_"
    $LASTEXITCODE = 1
    return
}

}