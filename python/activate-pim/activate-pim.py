"""Activate PIM roles or switch Azure/AKS context.

Usage:
    python activate-pim.py --activate
    python activate-pim.py --activate --duration PT4H
    python activate-pim.py --activate --justification "Investigating incident"
    python activate-pim.py --switch --subscription Soteria.Dev.01
    python activate-pim.py --config path/to/config.json --activate --dry-run

Modes:
    --activate  Activate PIM roles (existing behavior).
    --switch    Log in to Azure, set subscription, fetch AKS credentials,
                and convert kubeconfig with kubelogin.

Configuration:
    Reads from pim-config.json (next to this script) by default.
    Override with --config. See pim-config.json for format.

Prerequisites:
    - Azure CLI installed
    - kubelogin installed (for --switch mode)
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
import uuid

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CONFIG_PATH = os.path.join(SCRIPT_DIR, "pim-config.json")

# ANSI color codes
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"


def load_config(config_path: str) -> dict:
    """Load configuration from a JSON file."""
    if not os.path.exists(config_path):
        print(f"ERROR: Config file not found: {config_path}")
        print("Create one with the following format:")
        print(json.dumps({
            "subscriptions": {"MySubscription": "<subscription-id>"},
            "default_duration": "PT8H",
            "default_justification": "Development work",
        }, indent=4))
        sys.exit(1)
    with open(config_path) as f:
        return json.load(f)


def get_access_token() -> str:
    """Get an Azure access token via az cli."""
    result = subprocess.run(
        "az account get-access-token --query accessToken -o tsv",
        shell=True,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Failed to get access token. Are you logged in? Run 'az login'.")
        print(result.stderr)
        sys.exit(1)
    return result.stdout.strip()


def get_principal_id(token: str) -> str:
    """Get the current user's principal/object ID."""
    result = subprocess.run(
        "az ad signed-in-user show --query id -o tsv",
        shell=True,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("ERROR: Failed to get signed-in user info.")
        print(result.stderr)
        sys.exit(1)
    return result.stdout.strip()


def get_eligible_roles(token: str, subscription_id: str) -> list[dict]:
    """List PIM-eligible roles for the current user on a subscription."""
    url = (
        f"https://management.azure.com/subscriptions/{subscription_id}"
        f"/providers/Microsoft.Authorization/roleEligibilityScheduleInstances"
        f"?api-version=2020-10-01&$filter=asTarget()"
    )
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        resp = urllib.request.urlopen(req)
        data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"  WARNING: Failed to list eligible roles ({e.code}): {error_body}")
        return []

    roles = []
    for item in data.get("value", []):
        props = item["properties"]
        roles.append(
            {
                "name": props["expandedProperties"]["roleDefinition"]["displayName"],
                "role_definition_id": props["roleDefinitionId"],
                "scope": props["scope"],
            }
        )
    return roles


def activate_role(
    token: str,
    principal_id: str,
    role_definition_id: str,
    scope: str,
    duration: str,
    justification: str,
) -> dict:
    """Activate a PIM role assignment."""
    request_id = str(uuid.uuid4())
    url = (
        f"https://management.azure.com{scope}"
        f"/providers/Microsoft.Authorization/roleAssignmentScheduleRequests"
        f"/{request_id}?api-version=2020-10-01"
    )
    body = json.dumps(
        {
            "properties": {
                "principalId": principal_id,
                "roleDefinitionId": role_definition_id,
                "requestType": "SelfActivate",
                "justification": justification,
                "scheduleInfo": {
                    "expiration": {"type": "AfterDuration", "duration": duration}
                },
            }
        }
    ).encode()

    req = urllib.request.Request(
        url,
        data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="PUT",
    )
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        return {"error": f"HTTP {e.code}: {error_body}"}


def get_subscription_id(sub_entry) -> str:
    """Extract the subscription ID from a config entry (string or dict)."""
    if isinstance(sub_entry, str):
        return sub_entry
    return sub_entry["id"]


def run_switch(config: dict, subscription_name: str | None):
    """Log in to Azure, set subscription, fetch AKS credentials, and convert with kubelogin."""
    subs = config.get("subscriptions", {})

    if not subscription_name:
        print("ERROR: --switch requires --subscription to specify which subscription to switch to.")
        print(f"Available: {', '.join(subs.keys())}")
        sys.exit(1)

    if subscription_name not in subs:
        print(f"ERROR: Unknown subscription '{subscription_name}'. Available: {', '.join(subs.keys())}")
        sys.exit(1)

    sub_entry = subs[subscription_name]
    if isinstance(sub_entry, str):
        print(f"ERROR: Subscription '{subscription_name}' has no AKS configuration.")
        print("Add aks_resource_group and aks_cluster_name to the config entry.")
        sys.exit(1)

    sub_id = sub_entry["id"]
    rg = sub_entry.get("aks_resource_group")
    cluster = sub_entry.get("aks_cluster_name")

    if not rg or not cluster:
        print(f"ERROR: Subscription '{subscription_name}' is missing aks_resource_group or aks_cluster_name.")
        sys.exit(1)

    # Step 1: az login (scoped to tenant to skip subscription picker)
    tenant_id = config.get("tenant_id", "")
    print("Logging in to Azure...")
    login_cmd = "az login"
    if tenant_id:
        login_cmd += f" --tenant {tenant_id}"
    login_cmd += " --output none"
    result = subprocess.run(login_cmd, shell=True)
    if result.returncode != 0:
        print(f"{RED}ERROR: az login failed.{RESET}")
        sys.exit(1)

    # Step 2: Set subscription
    print(f"\nSetting subscription to {subscription_name} ({sub_id})...")
    result = subprocess.run(f"az account set --subscription {sub_id}", shell=True)
    if result.returncode != 0:
        print(f"{RED}ERROR: Failed to set subscription.{RESET}")
        sys.exit(1)

    # Step 3: Get AKS credentials
    print(f"\nFetching AKS credentials for {cluster} in {rg}...")
    result = subprocess.run(
        f"az aks get-credentials --resource-group {rg} --name {cluster} --overwrite-existing",
        shell=True,
    )
    if result.returncode != 0:
        print(f"{RED}ERROR: Failed to get AKS credentials.{RESET}")
        sys.exit(1)

    # Step 4: kubelogin convert
    print("\nConverting kubeconfig with kubelogin...")
    result = subprocess.run("kubelogin convert-kubeconfig -l azurecli", shell=True)
    if result.returncode != 0:
        print(f"{RED}ERROR: kubelogin convert failed.{RESET}")
        sys.exit(1)

    # Step 5: Verify kubectl connectivity
    print("\nVerifying kubectl access...")
    result = subprocess.run("kubectl get pods --all-namespaces", shell=True)
    if result.returncode != 0:
        print(f"{RED}FAILED: kubectl get pods failed. Cluster may not be reachable.{RESET}")
        sys.exit(1)

    print(f"\n{GREEN}Done. Switched to {subscription_name} / AKS cluster {cluster}.{RESET}")


def run_activate(config: dict, args):
    """Activate PIM roles (original behavior)."""
    subs = config.get("subscriptions", {})
    duration = args.duration or config.get("default_duration", "PT8H")
    justification = args.justification or config.get("default_justification", "Development work")

    print("Getting access token...")
    token = get_access_token()

    print("Getting principal ID...")
    principal_id = get_principal_id(token)
    print(f"  Principal ID: {principal_id}")

    # Filter subscriptions if specified
    if args.subscription:
        if args.subscription not in subs:
            print(f"ERROR: Unknown subscription '{args.subscription}'. Available: {', '.join(subs.keys())}")
            sys.exit(1)
        subs = {args.subscription: subs[args.subscription]}

    activated = 0
    for sub_name, sub_entry in subs.items():
        sub_id = get_subscription_id(sub_entry)
        print(f"\n{'='*60}")
        print(f"Subscription: {sub_name} ({sub_id})")
        print(f"{'='*60}")

        roles = get_eligible_roles(token, sub_id)
        if not roles:
            print("  No eligible PIM roles found.")
            continue

        # Filter roles if specified
        if args.role:
            roles = [r for r in roles if r["name"] == args.role]
            if not roles:
                print(f"  Role '{args.role}' not found among eligible roles.")
                continue

        for role in roles:
            print(f"\n  Role: {role['name']}")
            print(f"  Scope: {role['scope']}")

            if args.dry_run:
                print("  [DRY RUN] Would activate this role.")
                continue

            print(f"  Activating for {duration} ...")
            result = activate_role(
                token, principal_id, role["role_definition_id"],
                role["scope"], duration, justification,
            )
            if "error" in result:
                print(f"  {RED}FAILED: {result['error']}{RESET}")
            else:
                status = result.get("properties", {}).get("status", "Unknown")
                print(f"  {GREEN}SUCCESS! Status: {status}{RESET}")
                activated += 1

    print(f"\n{'='*60}")
    if args.dry_run:
        print("Dry run complete. No roles were activated.")
    elif activated > 0:
        print(f"{GREEN}Done. Activated {activated} role(s) for {duration}.{RESET}")
    else:
        print(f"{RED}Done. No roles were activated.{RESET}")


def main():
    parser = argparse.ArgumentParser(description="Activate PIM roles or switch Azure/AKS context.")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--activate", action="store_true", help="Activate PIM roles")
    mode.add_argument("--switch", action="store_true", help="Switch subscription and fetch AKS credentials")

    parser.add_argument("--config", default=DEFAULT_CONFIG_PATH, help="Path to config JSON (default: pim-config.json next to script)")
    parser.add_argument("--subscription", help="Target a specific subscription (by name from config)")
    parser.add_argument("--role", help="Activate a specific role only (by display name)")
    parser.add_argument("--duration", help="Activation duration in ISO 8601 (default: from config)")
    parser.add_argument("--justification", help="Justification text (default: from config)")
    parser.add_argument("--dry-run", action="store_true", help="List eligible roles without activating")
    args = parser.parse_args()

    config = load_config(args.config)

    if args.switch:
        run_switch(config, args.subscription)
    else:
        run_activate(config, args)


if __name__ == "__main__":
    main()
