function global:switchgdk($newGdkVersion)
{
    $elevated = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($elevated)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    
    if ($principal.IsInRole($adminRole))
    {
        Write-Host -ForegroundColor Green "Script is running as Administrator"
    }
    else
    {
        Write-Host -ForegroundColor Red "Script is NOT running as Administrator, exiting"
        return
    }

    $parentFolder = (gci env:GameDK).Value

    if([String]::IsNullOREmpty($parentFolder))
    {
        Write-Host -ForegroundColor Red "No GDKs installed"
        return
    }

    # Find all GDK triplets
    $foldersSet = Get-ChildItem -Path $parentFolder -Attributes Directory | Where-Object { $_.FullName -match "[0-9]{6}" } | % { $_.FullName }

    $vals = (gci env:GameDKLatest).Value.TrimEnd("\").Split("\")
    $gdkVersion = $vals[$vals.Length - 1]
    Write-Host "Current GDK version is $gdkVersion"
    Write-Host "Desired version is $newGdkVersion"

    $tripletsSet = @()
    foreach($triplet in $foldersSet)
    {
        $vals = $triplet.TrimEnd("\").Split("\")
        $tripletDate = $vals[$vals.Length - 1]

        Write-Host "Found GDK triplet: $tripletDate"
        $tripletsSet += $tripletDate
    }

    if($tripletsSet -notcontains $newGdkVersion)
    {
        Write-Host -ForegroundColor Red "Failed to find desired GDK version: $newGdkVersion"
        return
    }
    else
    {
        Write-Host -ForegroundColor Green "Found GDK version $newGdkVersion, performing switch"
    }

    Write-Host "Setting environment variables..."
    [System.Environment]::SetEnvironmentVariable("GameDK", "C:\Program Files (x86)\Microsoft GDK\", "Machine")
    [System.Environment]::SetEnvironmentVariable("GameDKLatest", "C:\Program Files (x86)\Microsoft GDK\$newGdkVersion", "Machine")
    [System.Environment]::SetEnvironmentVariable("GRDKLatest", "C:\Program Files (x86)\Microsoft GDK\$newGdkVersion\GRDK", "Machine")
    [System.Environment]::SetEnvironmentVariable("GXDKLatest", "C:\Program Files (x86)\Microsoft GDK\$newGdkVersion\GXDK", "Machine")

    Write-Host -ForegroundColor Green "Done! Restart all programs that depend on the environment being updated"
}