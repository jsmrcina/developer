# Creates a file with the specified file name, NOTE: WILL OVERWRITE ANY EXISTING FILE WITH THIS NAME WITHOUT WARNING
function global:touch($fileName)
{
    echo $null >> $fileName
}