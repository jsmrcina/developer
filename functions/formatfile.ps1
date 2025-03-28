. $global:developerFolderPath\functions\checktool.ps1

function global:formatfile($fileName, $formatFile = "$global:developerFolderPath\.clang-format")
{
    $result = checkTool "clang-format.exe"
    if (-not $result)
    {
        return
    }

    clang-format.exe -i -style=file:"$formatFile" $fileName
}