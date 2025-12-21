#!/usr/bin/env python3
"""
Playwright Authentication Manager

Manages browser sessions with persistent authentication for use with Playwright automation.
Sessions are stored in ~/.playwright-profiles/<profile-name>/

Usage:
    playwright-auth.py login <profile>    - Interactive login, saves session
    playwright-auth.py check <profile>    - Check if session exists and show info
    playwright-auth.py list               - List all saved profiles
    playwright-auth.py delete <profile>   - Delete a saved profile
    playwright-auth.py open <profile> [url] - Open browser with saved session

Examples:
    playwright-auth.py login google
    playwright-auth.py check google
    playwright-auth.py open google https://console.cloud.google.com
"""

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

PROFILES_DIR = Path.home() / ".playwright-profiles"


def get_profile_path(profile_name: str) -> Path:
    """Get the directory path for a profile."""
    return PROFILES_DIR / profile_name


def cmd_login(args):
    """Interactive login - opens browser for manual auth, saves session."""
    from playwright.sync_api import sync_playwright

    profile_path = get_profile_path(args.profile)
    profile_path.mkdir(parents=True, exist_ok=True)

    url = args.url or "https://accounts.google.com"

    print(f"Opening browser for login...")
    print(f"Profile will be saved to: {profile_path}")
    print(f"Starting URL: {url}")
    print()
    print("Complete your login in the browser window.")
    print("Close the browser when done, or press Ctrl+C here.")
    print()

    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=str(profile_path),
            headless=False,
            viewport={"width": 1280, "height": 900},
            # Reduce bot detection
            args=[
                "--disable-blink-features=AutomationControlled",
            ],
        )

        page = context.pages[0] if context.pages else context.new_page()
        page.goto(url)

        try:
            # Wait indefinitely until browser is closed
            page.wait_for_event("close", timeout=0)
        except KeyboardInterrupt:
            print("\nClosing browser...")
        except Exception:
            pass  # Browser was closed

        context.close()

    print(f"\nSession saved to: {profile_path}")
    print(f"Use with: playwright-auth.py open {args.profile} <url>")


def cmd_check(args):
    """Check if a profile exists and show info."""
    profile_path = get_profile_path(args.profile)

    if not profile_path.exists():
        print(f"Profile '{args.profile}' does not exist.")
        print(f"Create it with: playwright-auth.py login {args.profile}")
        sys.exit(1)

    # Get directory size
    total_size = sum(f.stat().st_size for f in profile_path.rglob("*") if f.is_file())
    size_mb = total_size / (1024 * 1024)

    # Check for cookies
    cookies_file = profile_path / "Default" / "Cookies"
    has_cookies = cookies_file.exists()

    print(f"Profile: {args.profile}")
    print(f"Path: {profile_path}")
    print(f"Size: {size_mb:.1f} MB")
    print(f"Has cookies: {has_cookies}")

    # Show modification time
    import datetime
    mtime = datetime.datetime.fromtimestamp(profile_path.stat().st_mtime)
    print(f"Last modified: {mtime.strftime('%Y-%m-%d %H:%M:%S')}")


def cmd_list(args):
    """List all saved profiles."""
    if not PROFILES_DIR.exists():
        print("No profiles found.")
        print(f"Profiles directory: {PROFILES_DIR}")
        return

    profiles = [d.name for d in PROFILES_DIR.iterdir() if d.is_dir()]

    if not profiles:
        print("No profiles found.")
        return

    print(f"Saved profiles ({PROFILES_DIR}):")
    for profile in sorted(profiles):
        profile_path = get_profile_path(profile)
        total_size = sum(f.stat().st_size for f in profile_path.rglob("*") if f.is_file())
        size_mb = total_size / (1024 * 1024)
        print(f"  - {profile} ({size_mb:.1f} MB)")


def cmd_delete(args):
    """Delete a saved profile."""
    profile_path = get_profile_path(args.profile)

    if not profile_path.exists():
        print(f"Profile '{args.profile}' does not exist.")
        sys.exit(1)

    if not args.force:
        response = input(f"Delete profile '{args.profile}'? [y/N] ")
        if response.lower() != 'y':
            print("Cancelled.")
            return

    shutil.rmtree(profile_path)
    print(f"Deleted profile: {args.profile}")


def cmd_open(args):
    """Open browser with saved session."""
    from playwright.sync_api import sync_playwright

    profile_path = get_profile_path(args.profile)

    if not profile_path.exists():
        print(f"Profile '{args.profile}' does not exist.")
        print(f"Create it with: playwright-auth.py login {args.profile}")
        sys.exit(1)

    url = args.url or "about:blank"

    print(f"Opening browser with profile '{args.profile}'...")
    print(f"URL: {url}")
    print("Close the browser when done.")

    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=str(profile_path),
            headless=False,
            viewport={"width": 1280, "height": 900},
            args=[
                "--disable-blink-features=AutomationControlled",
            ],
        )

        page = context.pages[0] if context.pages else context.new_page()
        page.goto(url)

        try:
            page.wait_for_event("close", timeout=0)
        except KeyboardInterrupt:
            print("\nClosing browser...")
        except Exception:
            pass

        context.close()


def main():
    parser = argparse.ArgumentParser(
        description="Manage Playwright browser sessions with persistent authentication",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # login
    login_parser = subparsers.add_parser("login", help="Interactive login, saves session")
    login_parser.add_argument("profile", help="Profile name (e.g., 'google', 'github')")
    login_parser.add_argument("--url", "-u", help="Starting URL (default: Google accounts)")
    login_parser.set_defaults(func=cmd_login)

    # check
    check_parser = subparsers.add_parser("check", help="Check if session exists")
    check_parser.add_argument("profile", help="Profile name")
    check_parser.set_defaults(func=cmd_check)

    # list
    list_parser = subparsers.add_parser("list", help="List all saved profiles")
    list_parser.set_defaults(func=cmd_list)

    # delete
    delete_parser = subparsers.add_parser("delete", help="Delete a saved profile")
    delete_parser.add_argument("profile", help="Profile name")
    delete_parser.add_argument("--force", "-f", action="store_true", help="Skip confirmation")
    delete_parser.set_defaults(func=cmd_delete)

    # open
    open_parser = subparsers.add_parser("open", help="Open browser with saved session")
    open_parser.add_argument("profile", help="Profile name")
    open_parser.add_argument("url", nargs="?", help="URL to open")
    open_parser.set_defaults(func=cmd_open)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
