# Creates an empty file, or updates the timestamp of an existing one.
# Matches the semantics of the Unix "touch" command, which this shadows on Linux.
function global:touch($fileName)
{
    if (Test-Path -LiteralPath $fileName)
    {
        (Get-Item -LiteralPath $fileName).LastWriteTime = Get-Date
    }
    else
    {
        New-Item -ItemType File -Path $fileName | Out-Null
    }
}
