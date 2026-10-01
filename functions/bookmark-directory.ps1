function global:Bookmark-Directory
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = '.'
    )

    if ([string]::IsNullOrWhiteSpace($Name))
    {
        throw "Bookmark name cannot be empty."
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container))
    {
        throw "Bookmark path is not a directory: $resolvedPath"
    }

    $userProfile = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($userProfile))
    {
        $userProfile = [Environment]::GetFolderPath('UserProfile')
    }

    $developerDirectory = Join-Path $userProfile '.developer'
    $bookmarkFile = Join-Path $developerDirectory 'bookmarks.json'
    New-Item -ItemType Directory -Path $developerDirectory -Force -ErrorAction Stop | Out-Null

    $bookmarks = [ordered]@{}
    if (Test-Path -LiteralPath $bookmarkFile -PathType Leaf)
    {
        $savedBookmarks = Get-Content -LiteralPath $bookmarkFile -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop

        foreach ($bookmark in $savedBookmarks.PSObject.Properties)
        {
            $bookmarks[$bookmark.Name] = [string] $bookmark.Value
        }
    }

    $existingName = $bookmarks.Keys |
        Where-Object { $_ -ieq $Name } |
        Select-Object -First 1

    if ($null -ne $existingName)
    {
        $bookmarks[$existingName] = $resolvedPath
    }
    else
    {
        $bookmarks[$Name] = $resolvedPath
    }

    $temporaryFile = Join-Path $developerDirectory ([IO.Path]::GetRandomFileName())
    try
    {
        $bookmarks |
            ConvertTo-Json |
            Set-Content -LiteralPath $temporaryFile -Encoding UTF8 -ErrorAction Stop
        Move-Item -LiteralPath $temporaryFile -Destination $bookmarkFile -Force -ErrorAction Stop
    }
    finally
    {
        Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
    }

    Write-Host -ForegroundColor Green "Bookmarked '$Name' as '$resolvedPath'."
}

Set-Alias -Name bd -Value Bookmark-Directory -Scope Global -Force
