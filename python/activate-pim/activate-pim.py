"""Activate PIM (Privileged Identity Management) roles on Azure subscriptions.

Usage:
    python scripts/activate-pim.py
    python scripts/activate-pim.py --duration PT4H
    python scripts/activate-pim.py --justification "Investigating incident"
    python scripts/activate-pim.py --config path/to/config.json
    python scripts/activate-pim.py --dry-run

Configuration:
    Reads from pim-config.json (next to this script) by default.
    Override with --config. See pim-config.json for format.

Prerequisites:
    - Azure CLI installed and logged in (`az login`)
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


def main():
    parser = argparse.ArgumentParser(description="Activate PIM roles on Azure subscriptions.")
    parser.add_argument("--config", default=DEFAULT_CONFIG_PATH, help=f"Path to config JSON (default: pim-config.json next to script)")
    parser.add_argument(
        "--subscription",
        help="Activate on a specific subscription only (by name from config)",
    )
    parser.add_argument(
        "--role",
        help="Activate a specific role only (by display name)",
    )
    parser.add_argument("--duration", help="Activation duration in ISO 8601 (default: from config)")
    parser.add_argument("--justification", help="Justification text (default: from config)")
    parser.add_argument("--dry-run", action="store_true", help="List eligible roles without activating")
    args = parser.parse_args()

    config = load_config(args.config)
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
    for sub_name, sub_id in subs.items():
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
                print(f"  FAILED: {result['error']}")
            else:
                status = result.get("properties", {}).get("status", "Unknown")
                print(f"  SUCCESS! Status: {status}")
                activated += 1

    print(f"\n{'='*60}")
    if args.dry_run:
        print("Dry run complete. No roles were activated.")
    else:
        print(f"Done. Activated {activated} role(s) for {duration}.")


if __name__ == "__main__":
    main()
