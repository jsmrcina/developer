<#
.SYNOPSIS
    Activate PIM roles or switch Azure/AKS context. PowerShell port
    of activate-pim.py.

.DESCRIPTION
    This is a Constrained Language Mode (CLM) safe rewrite of activate-pim.py.

    CLM-safety notes (why it is written the way it is):
      * No [pscustomobject] casts   -> request bodies are built from hashtables
                                        (@{}) and serialized with ConvertTo-Json.
      * No New-Object / Add-Type    -> HTTP is done with Invoke-RestMethod, and
                                        HTTP error bodies are read from
                                        $_.ErrorDetails.Message (no StreamReader).
      * No [guid]::NewGuid() reliance -> request IDs use the New-Guid cmdlet.
      * Only cmdlets + core types are used; external tools (az/kubelogin/kubectl)
        are invoked as processes, which is always allowed under CLM.

.PARAMETER Activate
    Activate PIM roles (default behavior of the Python script).

.PARAMETER Switch
    Log in to Azure, set the subscription, fetch AKS credentials and convert the
    kubeconfig with kubelogin.

.PARAMETER Config
    Path to the config JSON. Defaults to pim-config.json next to this script
    (the same file the Python version uses).

.PARAMETER Subscription
    Target a specific subscription by its name (key) from the config.

.PARAMETER Role
    Activate only the role with this display name.

.PARAMETER Duration
    Activation duration in ISO 8601 (e.g. PT4H). Defaults to config value.

.PARAMETER Justification
    Justification text. Defaults to config value.

.PARAMETER DryRun
    List eligible roles without activating anything.

.EXAMPLE
    .\activate-pim.ps1 -Activate

.EXAMPLE
    .\activate-pim.ps1 -Activate -Duration PT4H -Justification "Investigating incident"

.NOTES
    Prerequisites: Azure CLI (az). -Switch also needs kubelogin and kubectl.

    Alternative: if your Software Center offers a sanctioned Python ("SPython"),
    activate-pim.py uses only the Python standard library and will run as-is,
    which avoids the CLM constraints entirely.
#>
[CmdletBinding()]
param(
    [switch]$Activate,
    [switch]$Switch,
    [string]$Config,
    [string]$Subscription,
    [string]$Role,
    [string]$Duration,
    [string]$Justification,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Get-PimConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "ERROR: Config file not found: $Path"
        Write-Host "Create one with the following format:"
        $template = @{
            subscriptions         = @{ MySubscription = "<subscription-id>" }
            default_duration      = "PT8H"
            default_justification = "Development work"
        }
        Write-Host ($template | ConvertTo-Json -Depth 5)
        exit 1
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    return ($raw | ConvertFrom-Json)
}

function Get-AccessToken {
    $token = az account get-access-token --query accessToken -o tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $token) {
        Write-Host "ERROR: Failed to get access token. Are you logged in? Run 'az login'."
        exit 1
    }
    return $token.Trim()
}

function Get-PrincipalId {
    $id = az ad signed-in-user show --query id -o tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $id) {
        Write-Host "ERROR: Failed to get signed-in user info."
        exit 1
    }
    return $id.Trim()
}

function Get-HttpErrorText {
    param($ErrorRecord)

    $text = $ErrorRecord.ErrorDetails.Message
    if (-not $text) {
        $text = $ErrorRecord.Exception.Message
    }
    return $text
}

function Get-EligibleRoles {
    param([string]$Token, [string]$SubscriptionId)

    $url = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01&`$filter=asTarget()"
    try {
        $resp = Invoke-RestMethod -Uri $url -Method Get -Headers @{ Authorization = "Bearer $Token" }
    }
    catch {
        Write-Host "  WARNING: Failed to list eligible roles: $(Get-HttpErrorText $_)"
        return @()
    }

    $roles = @()
    foreach ($item in $resp.value) {
        $props = $item.properties
        $roles += @{
            name               = $props.expandedProperties.roleDefinition.displayName
            role_definition_id = $props.roleDefinitionId
            scope              = $props.scope
        }
    }
    return $roles
}

function Invoke-RoleActivation {
    param(
        [string]$Token,
        [string]$PrincipalId,
        [string]$RoleDefinitionId,
        [string]$Scope,
        [string]$Duration,
        [string]$Justification
    )

    $requestId = (New-Guid).Guid
    $url = "https://management.azure.com$Scope/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/${requestId}?api-version=2020-10-01"

    $body = @{
        properties = @{
            principalId      = $PrincipalId
            roleDefinitionId = $RoleDefinitionId
            requestType      = "SelfActivate"
            justification    = $Justification
            scheduleInfo     = @{
                expiration = @{ type = "AfterDuration"; duration = $Duration }
            }
        }
    }
    $json = $body | ConvertTo-Json -Depth 10 -Compress

    try {
        $resp = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/json" `
            -Headers @{ Authorization = "Bearer $Token" }
        $status = $resp.properties.status
        if (-not $status) { $status = "Unknown" }
        return @{ ok = $true; status = $status }
    }
    catch {
        return @{ ok = $false; error = (Get-HttpErrorText $_) }
    }
}

function Get-SubscriptionNames {
    param($Subscriptions)
    return ($Subscriptions | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })
}

function Get-SubscriptionId {
    param($Entry)
    if ($Entry -is [string]) { return $Entry }
    return $Entry.id
}

function Invoke-Switch {
    param($Config, [string]$SubscriptionName)

    $subs = $Config.subscriptions
    $names = @(Get-SubscriptionNames $subs)

    if (-not $SubscriptionName) {
        Write-Host "ERROR: -Switch requires -Subscription to specify which subscription to switch to."
        Write-Host "Available: $($names -join ', ')"
        exit 1
    }
    if ($names -notcontains $SubscriptionName) {
        Write-Host "ERROR: Unknown subscription '$SubscriptionName'. Available: $($names -join ', ')"
        exit 1
    }

    $entry = $subs.$SubscriptionName
    if ($entry -is [string]) {
        Write-Host "ERROR: Subscription '$SubscriptionName' has no AKS configuration."
        Write-Host "Add aks_resource_group and aks_cluster_name to the config entry."
        exit 1
    }

    $subId = $entry.id
    $rg = $entry.aks_resource_group
    $cluster = $entry.aks_cluster_name

    if (-not $rg -or -not $cluster) {
        Write-Host "ERROR: Subscription '$SubscriptionName' is missing aks_resource_group or aks_cluster_name."
        exit 1
    }

    $tenantId = $Config.tenant_id

    Write-Host "Logging in to Azure..."
    if ($tenantId) {
        az login --tenant $tenantId --output none
    }
    else {
        az login --output none
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: az login failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nSetting subscription to $SubscriptionName ($subId)..."
    az account set --subscription $subId
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to set subscription." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nFetching AKS credentials for $cluster in $rg..."
    az aks get-credentials --resource-group $rg --name $cluster --overwrite-existing
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to get AKS credentials." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nConverting kubeconfig with kubelogin..."
    kubelogin convert-kubeconfig -l azurecli
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: kubelogin convert failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nVerifying kubectl access..."
    kubectl get pods --all-namespaces
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: kubectl get pods failed. Cluster may not be reachable." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nDone. Switched to $SubscriptionName / AKS cluster $cluster." -ForegroundColor Green
}

function Invoke-Activate {
    param($Config)

    $subs = $Config.subscriptions
    $names = @(Get-SubscriptionNames $subs)

    $effectiveDuration = if ($Duration) { $Duration }
    elseif ($Config.default_duration) { $Config.default_duration }
    else { "PT8H" }

    $effectiveJustification = if ($Justification) { $Justification }
    elseif ($Config.default_justification) { $Config.default_justification }
    else { "Development work" }

    Write-Host "Getting access token..."
    $token = Get-AccessToken

    Write-Host "Getting principal ID..."
    $principalId = Get-PrincipalId
    Write-Host "  Principal ID: $principalId"

    if ($Subscription) {
        if ($names -notcontains $Subscription) {
            Write-Host "ERROR: Unknown subscription '$Subscription'. Available: $($names -join ', ')"
            exit 1
        }
        $names = @($Subscription)
    }

    $activated = 0
    foreach ($subName in $names) {
        $entry = $subs.$subName
        $subId = Get-SubscriptionId $entry

        Write-Host "`n$("=" * 60)"
        Write-Host "Subscription: $subName ($subId)"
        Write-Host ("=" * 60)

        $roles = @(Get-EligibleRoles -Token $token -SubscriptionId $subId)
        if ($roles.Count -eq 0) {
            Write-Host "  No eligible PIM roles found."
            continue
        }

        # Build the allowlist of role display names to activate.
        # Precedence: -Role (CLI) overrides the per-subscription "roles" config filter.
        # When no allowlist is set, all eligible roles are activated (original behavior).
        $allowlist = $null
        if ($Role) {
            $allowlist = @($Role)
        }
        elseif (($entry -isnot [string]) -and $entry.roles) {
            $allowlist = @($entry.roles)
        }

        if ($Role) {
            $matches = @($roles | Where-Object { $_.name -eq $Role })
            if ($matches.Count -eq 0) {
                Write-Host "  Role '$Role' not found among eligible roles."
                continue
            }
        }

        foreach ($r in $roles) {
            # Case-insensitive exact match against the allowlist ($null = allow all).
            $inAllowlist = ($null -eq $allowlist) -or ($allowlist -contains $r.name)

            if (-not $inAllowlist -and -not $DryRun) {
                continue
            }

            Write-Host "`n  Role: $($r.name)"
            Write-Host "  Scope: $($r.scope)"

            if ($DryRun) {
                if ($inAllowlist) {
                    Write-Host "  [DRY RUN] Would activate this role."
                }
                else {
                    Write-Host "  [DRY RUN] Skipped (not in roles filter)."
                }
                continue
            }

            Write-Host "  Activating for $effectiveDuration ..."
            $result = Invoke-RoleActivation -Token $token -PrincipalId $principalId `
                -RoleDefinitionId $r.role_definition_id -Scope $r.scope `
                -Duration $effectiveDuration -Justification $effectiveJustification

            if ($result.ok) {
                Write-Host "  SUCCESS! Status: $($result.status)" -ForegroundColor Green
                $activated++
            }
            else {
                Write-Host "  FAILED: $($result.error)" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n$("=" * 60)"
    if ($DryRun) {
        Write-Host "Dry run complete. No roles were activated."
    }
    elseif ($activated -gt 0) {
        Write-Host "Done. Activated $activated role(s) for $effectiveDuration." -ForegroundColor Green
    }
    else {
        Write-Host "Done. No roles were activated." -ForegroundColor Red
    }
}

# ---- main ----
if ($Activate -and $Switch) {
    Write-Host "ERROR: Specify only one of -Activate or -Switch."
    exit 1
}
if (-not $Activate -and -not $Switch) {
    Write-Host "ERROR: Specify one of -Activate or -Switch. Use 'Get-Help .\activate-pim.ps1' for usage."
    exit 1
}

if (-not $Config) {
    $Config = Join-Path $PSScriptRoot "pim-config.json"
}
$cfg = Get-PimConfig -Path $Config

if ($Switch) {
    Invoke-Switch -Config $cfg -SubscriptionName $Subscription
}
else {
    Invoke-Activate -Config $cfg
}
