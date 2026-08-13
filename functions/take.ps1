# Takes ownership of a folder tree and grants the current admin/user full access

function global:take([string] $folder)
{
  if (-not (Test-Path $folder))
  {
    Write-Error "The specified path does not exist."
    return
  }

  if ($global:isWindowsPlatform)
  {
    takeown /F $folder /R /A
    icacls $folder /grant Administrators:F /T
    return
  }

  # Unix equivalent: chown the tree to the current user and make it writable by them
  if (-not (Test-IsElevated))
  {
    Write-Host -ForegroundColor Yellow "Not running as root, using sudo..."
    sudo chown -R "$($env:USER):$($env:USER)" $folder
    sudo chmod -R u+rwX $folder
  }
  else
  {
    chown -R "$($env:USER):$($env:USER)" $folder
    chmod -R u+rwX $folder
  }
}
