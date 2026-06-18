<#
.SYNOPSIS
  Refreshes ~/.copilot/skills/ with junctions to every skill folder in the
  skill repo repo so that all Copilot CLI sessions discover them globally.

.DESCRIPTION
  Scans <RepoRoot>\.agents\skills and <RepoRoot>\plugins\*\skills for any
  subfolder containing a SKILL.md, then creates an NTFS junction at
  $env:USERPROFILE\.copilot\skills\<skill-name> pointing at the real folder.

  Idempotent:
    - Already-correct junctions are skipped
    - Junctions pointing at the wrong target are recreated
    - Real (non-junction) directories are left alone with a warning
    - Stale junctions whose target no longer exists are removed

.PARAMETER RepoRoot
  Path to the skill repo checkout. Required.

.PARAMETER Prune
  Remove junctions in ~/.copilot/skills/ that no longer correspond to a skill
  in the repo. Off by default.

.EXAMPLE
  pwsh -File $env:USERPROFILE\.copilot\refresh-skills.ps1 -RepoRoot C:\developer\git\skill_repo

.EXAMPLE
  pwsh -File $env:USERPROFILE\.copilot\refresh-skills.ps1 -RepoRoot D:\src\skill_repo  -Prune
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$RepoRoot,
  [switch]$Prune
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RepoRoot)) {
  Write-Error "RepoRoot not found: $RepoRoot"
  exit 1
}

$globalSkills = Join-Path $env:USERPROFILE '.copilot\skills'
if (-not (Test-Path $globalSkills)) {
  New-Item -ItemType Directory -Path $globalSkills | Out-Null
  Write-Host "[INFO]  Created $globalSkills"
}

# Discover every <skills>/<skill> folder that contains a SKILL.md
$skillParents = @((Join-Path $RepoRoot '.agents\skills'))
$pluginsDir   = Join-Path $RepoRoot 'plugins'
if (Test-Path $pluginsDir) {
  $skillParents += Get-ChildItem -Path $pluginsDir -Directory |
    ForEach-Object { Join-Path $_.FullName 'skills' } |
    Where-Object { Test-Path $_ }
}

$skills = foreach ($parent in $skillParents) {
  Get-ChildItem -Path $parent -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }
}

# Warn on duplicate names (junction names must be unique)
$skills | Group-Object Name | Where-Object { $_.Count -gt 1 } | ForEach-Object {
  Write-Host "[WARN]  Duplicate skill name '$($_.Name)':"
  $_.Group | ForEach-Object { Write-Host "          $($_.FullName)" }
  Write-Host "        Only the first occurrence will be linked."
}

$seen = @{}
$counts = @{ Created = 0; Skipped = 0; Relinked = 0; RealDir = 0; Failed = 0; Pruned = 0 }

foreach ($s in $skills) {
  if ($seen.ContainsKey($s.Name)) { continue }
  $seen[$s.Name] = $s.FullName

  $linkPath = Join-Path $globalSkills $s.Name

  if (Test-Path $linkPath) {
    $item = Get-Item -LiteralPath $linkPath -Force
    if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
      $currentTarget = $item.Target | Select-Object -First 1
      $desired = (Resolve-Path -LiteralPath $s.FullName).Path
      $actual  = if ($currentTarget) { (Resolve-Path -LiteralPath $currentTarget -ErrorAction SilentlyContinue).Path } else { $null }
      if ($actual -and $actual -eq $desired) {
        Write-Host "[SKIP]  $($s.Name)"
        $counts.Skipped++
        continue
      }
      cmd /c rmdir "$linkPath" 2>$null | Out-Null
      cmd /c mklink /J "$linkPath" "$($s.FullName)" | Out-Null
      Write-Host "[FIX]   $($s.Name) (target updated)"
      $counts.Relinked++
      continue
    } else {
      Write-Host "[WARN]  $($s.Name) - real directory exists, leaving alone"
      $counts.RealDir++
      continue
    }
  }

  cmd /c mklink /J "$linkPath" "$($s.FullName)" | Out-Null
  if (Test-Path $linkPath) {
    Write-Host "[OK]    $($s.Name)"
    $counts.Created++
  } else {
    Write-Host "[ERROR] $($s.Name) - mklink failed"
    $counts.Failed++
  }
}

# Optionally prune junctions whose target no longer exists or no longer maps to a discovered skill
if ($Prune) {
  $known = $seen.Keys
  Get-ChildItem -Force $globalSkills | ForEach-Object {
    if (-not ($_.LinkType -eq 'Junction' -or $_.LinkType -eq 'SymbolicLink')) { return }
    $target = $_.Target | Select-Object -First 1
    $orphan = $false
    if (-not $target) { $orphan = $true }
    elseif (-not (Test-Path $target)) { $orphan = $true }
    elseif ($known -notcontains $_.Name) { $orphan = $true }
    if ($orphan) {
      cmd /c rmdir "$($_.FullName)" 2>$null | Out-Null
      Write-Host "[PRUNE] $($_.Name)"
      $counts.Pruned++
    }
  }
}

Write-Host ""
Write-Host "Summary:"
$counts.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object {
  Write-Host ("  {0,-9} {1}" -f $_.Key, $_.Value)
}
Write-Host ("  Total link entries in $globalSkills : " + (Get-ChildItem -Force $globalSkills).Count)
