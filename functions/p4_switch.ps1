function global:p4_switch($address, $user, $clientDefinition)
{
    p4 set P4PORT=$address
    p4 set P4USER=$user
    p4 set P4CLIENT=$clientDefinition
}

function global:p4_switchf($file)
{
    $config = Get-Content $file | ConvertFrom-Json

    Write-Host $config
    Write-Host

    p4 set P4PORT=$config.address
    p4 set P4USER=$config.user
    p4 set P4CLIENT=$config.client
}