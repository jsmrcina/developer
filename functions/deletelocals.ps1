# Lists each local branch and lets you decide if you want to keep or delete it

function global:deletelocals
{
    # A real foreach loop, so that break/continue below behave as intended
    $locals = @(git branch --format='%(refname:short)')

    foreach($cur in $locals)
    {
        $cur = $cur.Trim()

        if([string]::IsNullOrWhiteSpace($cur))
        {
            continue
        }

        # Add protection to avoid accidentally deleting your local main/master
        if($cur -eq "main" -or $cur -eq "master")
        {
            Write-Host -ForegroundColor Yellow "Auto-skipped $cur"
            continue
        }

        $delete = (Read-Host "Do you want to delete $($cur)? (y/n/q)").ToLower()

        if($delete -eq 'y')
        {
            Write-Host -ForegroundColor Red "Deleted $cur"
            git branch -D $cur
        }
        elseif($delete -eq 'n')
        {
            Write-Host -ForegroundColor Green "Skipped $cur"
        }
        elseif($delete -eq 'q')
        {
            Write-Host -ForegroundColor Cyan "Exiting..."
            break
        }

        Write-Host ""
    }
}
