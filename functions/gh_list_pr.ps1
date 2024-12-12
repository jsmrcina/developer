function global:gh_list_pr()
{
  $file = ".\pr_descriptions.txt"
  $result = gh pr list -s all

  if ($result[0] -match "^\d+")
  {
      $number = [int]$matches[0]
  }

  Remove-Item $file

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