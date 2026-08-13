function global:formatfile($fileName, $formatFile = (Join-Path $global:developerFolderPath ".clang-format"))
{
    if (-not (checktool "clang-format"))
    {
        return
    }

    clang-format -i -style=file:"$formatFile" $fileName
}
