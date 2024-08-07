function global:take([string] $folder)
{
  takeown /F $folder /R /A
  icacls $folder /grant Administrators:F
  gci -Force -Recurse $folder | % { Write-Host $_.FullName; icacls $_.FullName /grant Administrators:F }
}