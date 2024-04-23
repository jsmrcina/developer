function prompt {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
  
    ([System.Environment]::NewLine + "$(Get-Location)" + [System.Environment]::NewLine + $(if($principal.IsInRole($adminRole)) { "A " } else { '' }) + '>> ')
  }