function global:funclist()
{
    Write-Host -ForegroundColor Green "Functions:"
    foreach($i in $global:dev_functions)
    {
        Write-Host $i
    }

    Write-Host ""

    Write-Host -ForegroundColor Green "Private Functions:"
    foreach($i in $global:pdev_functions)
    {
        Write-Host $i
    }
}