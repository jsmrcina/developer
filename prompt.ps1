function prompt
{
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    $gitBranch = ''
    try
    {
        $gitDir = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0)
        {
            $branch = git rev-parse --abbrev-ref HEAD
            $red = "`e[31m"
            $reset = "`e[0m"
            $gitBranch = "${red}[$branch]${reset} "
        }
    }
    catch {}

    $newline = [System.Environment]::NewLine
    $location = Get-Location

    return $newline + $gitBranch + $newline + $location + $newline + $(if ($principal.IsInRole($adminRole)) { 'A ' } else { '' }) + '>> '
}
