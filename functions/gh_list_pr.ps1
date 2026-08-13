function global:gh_list_pr()
{
  if (-not (checktool "gh"))
  {
      return
  }

  $file = Join-Path (Get-Location).Path "pr_descriptions.txt"
  $result = gh pr list -s all

  $number = 0
  if ($result[0] -match "^\d+")
  {
      $number = [int]$matches[0]
  }

  Remove-Item $file -ErrorAction SilentlyContinue

  $bar = "-------------------------------------------------------------------------"
  $x = 1
  while($x -lt $number + 1)
  {
    $output = gh pr view $x
    $bar | Out-File -FilePath $file -Append
    $output | Out-File -FilePath $file -Append
    $x = $x + 1
  }

  $bar | Out-File -FilePath $file -Append
}
