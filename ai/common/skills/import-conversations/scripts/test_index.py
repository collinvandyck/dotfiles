#!/usr/bin/env python3
"""Tests for index_conversations.py, run against the real ~/.claude/projects data.

Usage: python3 test_index.py
Exits non-zero on first failure. Writes nothing.
"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "index_conversations.py")
REQUIRED_KEYS = {
    "session_id",
    "path",
    "project",
    "cwd",
    "last_activity",
    "size_bytes",
    "message_count",
    "first_prompt",
    "last_prompt",
    "sampled_turns",
}


def run(*args):
    proc = subprocess.run(
        [sys.executable, SCRIPT, *args],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise AssertionError(f"exit {proc.returncode}; stderr:\n{proc.stderr}")
    return json.loads(proc.stdout)


def check(name, cond, detail=""):
    if not cond:
        raise AssertionError(f"FAIL: {name} {detail}")
    print(f"ok: {name}")


def main():
    rows = run("--limit", "8")
    check("returns a list", isinstance(rows, list))
    check("respects --limit", len(rows) <= 8, f"got {len(rows)}")
    check("found some conversations", len(rows) > 0)

    for r in rows:
        missing = REQUIRED_KEYS - set(r)
        check(f"row has all keys ({r.get('session_id','?')[:8]})", not missing, f"missing {missing}")

    # recency sort: last_activity descending
    times = [r["last_activity"] for r in rows]
    check("sorted by last_activity desc", times == sorted(times, reverse=True))

    # at least one row has a non-empty first prompt that isn't a slash command / noise
    realish = [
        r for r in rows
        if r["first_prompt"]
        and not r["first_prompt"].lstrip().startswith("<")
        and not r["first_prompt"].lstrip().startswith("Caveat")
    ]
    check("at least one clean first_prompt", len(realish) > 0)

    # project name is readable (no leading dash-slug)
    check("project not a slug", all(not r["project"].startswith("-Users") for r in rows))

    # --exclude-current removes that session
    if rows:
        victim = rows[0]["session_id"]
        rows2 = run("--limit", "50", "--exclude-current", victim)
        check("exclude-current drops the session", all(r["session_id"] != victim for r in rows2))

    # every substantial conversation yields SOME preview signal (real prompt or
    # the slash-command that kicked it off) -- no blank picker cards.
    substantial = run("--limit", "60", "--min-messages", "10")
    blank = [r for r in substantial if not r["first_prompt"].strip()]
    check(
        "no blank first_prompt on substantial convos",
        not blank,
        f"{len(blank)} blanks, e.g. {[r['session_id'][:8] for r in blank[:3]]}",
    )

    # prompts must not be harness-injected noise (task notifications, reminders)
    noisy = [
        r for r in substantial
        for field in ("first_prompt", "last_prompt")
        if r[field].lstrip().lower().startswith(("<task-notification", "<system-reminder"))
    ]
    check(
        "no harness-noise prompts",
        not noisy,
        f"{len(noisy)} noisy, e.g. {[r['session_id'][:8] for r in noisy[:3]]}",
    )

    # --project filters by cwd substring
    proj_rows = run("--limit", "50", "--project", "temporal")
    check(
        "--project filters by cwd",
        all("temporal" in r["cwd"].lower() for r in proj_rows),
    )

    # --out writes to a file (creating parent dirs) instead of stdout
    out_path = "/tmp/import-conversations-test/nested/index.json"
    if os.path.exists(out_path):
        os.remove(out_path)
    proc = subprocess.run(
        [sys.executable, SCRIPT, "--limit", "3", "--out", out_path],
        capture_output=True, text=True,
    )
    check("--out exits 0", proc.returncode == 0, proc.stderr)
    check("--out creates the file (and parent dirs)", os.path.exists(out_path))
    check("--out keeps stdout clean", proc.stdout.strip() == "")
    with open(out_path) as fh:
        written = json.load(fh)
    check("--out file is valid + bounded", isinstance(written, list) and len(written) <= 3)

    print(f"\nALL PASSED ({len(rows)} rows sampled)")


if __name__ == "__main__":
    main()
