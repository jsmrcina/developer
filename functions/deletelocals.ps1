# Lists each local branch and lets you decide if you want to keep or delete it

function global:deletelocals
{
    $locals = $(git branch).Split("\n")
    $locals | % {
        $cur = $_.Trim().Trim('*').Trim()

        # Add protection to avoid accidentally deleting your local main/master
        if($cur -eq "main" -or $cur -eq "master")
        {
            Write-Host -Foreground Yellow "Auto-skipped $cur"
            continue;
        }
        else
        {
            $delete = (Read-Host "Do you want to delete $($cur)? (y/n/q)").ToLower()

            if($delete -eq 'y')
            {
                Write-Host -Foreground Red "Deleted $cur"
                git branch -D $cur
            }
            elseif($delete -eq 'n')
            {
                Write-Host -Foreground Green "Skipped $cur"
            }
            elseif($delete -eq 'q')
            {
                Write-Host -Foreground Cyan "Exiting..."
                break;
            }

            Write-Host ""
        }
    }
}