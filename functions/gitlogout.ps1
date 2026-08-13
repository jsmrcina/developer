function gitlogout
{
    param
    (
        [string] $firstCommit,
        [string] $lastCommit,
        [bool] $toConsole = $true,
        [string] $fileName = "git_log.csv",
        [bool] $firstParent = $true
    )

    # Build the argument list so that an unused --first-parent doesn't get passed
    # to git as an empty string, which it rejects as an ambiguous argument
    $gitArgs = @('log')
    if($firstParent)
    {
        $gitArgs += '--first-parent'
    }
    $gitArgs += '--pretty=format:%h|%cn|%s|%ce|%cd'
    $gitArgs += "$firstCommit..$lastCommit"

    $result = git @gitArgs | ForEach-Object {
        $fields = $_ -split "\|"
        [PSCustomObject]@{
            Hash      = $fields[0]
            Committer = $fields[1]
            Message   = $fields[2]
            Email     = $fields[3]
            Date      = $fields[4]
        }
    }

    if($toConsole)
    {
        $result | Format-Table -AutoSize
    }
    else
    {
        $result | Export-Csv -Path $fileName -NoTypeInformation
    }
}
