function global:GoTo-Bookmark
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $userProfile = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($userProfile))
    {
        $userProfile = [Environment]::GetFolderPath('UserProfile')
    }

    $bookmarkFile = Join-Path (Join-Path $userProfile '.developer') 'bookmarks.json'

    if (-not (Test-Path -LiteralPath $bookmarkFile -PathType Leaf))
    {
        throw "No directory bookmarks have been saved."
    }

    $bookmarks = Get-Content -LiteralPath $bookmarkFile -Raw -ErrorAction Stop |
        ConvertFrom-Json -ErrorAction Stop
    $bookmark = $bookmarks.PSObject.Properties |
        Where-Object { $_.Name -ieq $Name } |
        Select-Object -First 1

    if ($null -eq $bookmark)
    {
        throw "Directory bookmark '$Name' was not found."
    }

    $path = [string] $bookmark.Value
    if (-not (Test-Path -LiteralPath $path -PathType Container))
    {
        throw "Directory bookmark '$Name' points to a missing directory: $path"
    }

    Set-Location -LiteralPath $path
}

Set-Alias -Name goto -Value GoTo-Bookmark -Scope Global -Force
