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

    $fpArg = ""
    if($firstParent)
    {
        $fpArg = "--first-parent"
    }

    $result = `git log $fpArg --pretty=format:"%h|%cn|%s|%ce|%cd" "$firstCommit..$lastCommit" | % { $fields = $_ -split "\|"
         [PSCustomObject]@{
             Hash      = $fields[0]
             Message   = $fields[1]
             Committer = $fields[2]
             Email     = $fields[3]
             Date      = $fields[4]
         }
    }`

    if($toConsole)
    {
        $result | Format-Table -AutoSize
    }
    else
    {
        $result | Export-Csv -Path $fileName -NoTypeInformation
    }
}