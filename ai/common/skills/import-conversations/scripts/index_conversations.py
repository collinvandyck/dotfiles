#!/usr/bin/env python3
"""Mechanically skim every Claude Code conversation transcript.

Scans ~/.claude/projects/*/*.jsonl and emits a compact JSON array, one entry
per conversation, with just enough signal for a ranking pass to work from
without ever opening a raw transcript. No LLM, no token cost.

Run with --help for flags. Output goes to stdout; status to stderr.
"""

import argparse
import datetime as dt
import glob
import json
import os
import sys

PROMPT_TRIM = 240          # max chars kept per prompt/turn
MAX_SAMPLED_TURNS = 5      # evenly-spaced user turns kept for ranking signal

# Prefixes that mark a "user" record as harness noise rather than a real prompt.
NOISE_PREFIXES = (
    "<command",
    "<local-command",
    "<bash-input",
    "<bash-stdout",
    "<local-command-stdout",
    "<system-reminder",
    "<task-notification",
    "caveat:",
)


def human_size(n):
    size = float(n)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            if unit == "B":
                return f"{int(size)}B"
            return f"{size:.1f}{unit}".replace(".0", "")
        size /= 1024
    return f"{size:.1f}GB"


def text_of(message):
    """Extract plain user text from a message; '' if it carries no real text."""
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
        return "\n".join(parts)
    return ""


def is_real_prompt(text):
    s = text.strip()
    if not s:
        return False
    low = s.lower()
    return not any(low.startswith(p) for p in NOISE_PREFIXES)


def command_invocation(text):
    """If text is a slash-command kickoff, render it as '/name args'; else ''."""
    if "<command-name>" not in text:
        return ""
    import re
    name = re.search(r"<command-name>(.*?)</command-name>", text, re.S)
    cmd_args = re.search(r"<command-args>(.*?)</command-args>", text, re.S)
    if not name:
        return ""
    parts = [name.group(1).strip()]
    if cmd_args and cmd_args.group(1).strip():
        parts.append(cmd_args.group(1).strip())
    return " ".join(parts)


def trim(text):
    return " ".join(text.split())[:PROMPT_TRIM]


def project_name(cwd, slug):
    """Readable project label derived from cwd, never the dash-slug."""
    home = os.path.expanduser("~")
    if cwd:
        code = os.path.join(home, "code")
        if cwd.startswith(code + os.sep):
            return cwd[len(code) + 1:]
        if cwd.startswith(home + os.sep):
            return cwd[len(home) + 1:]
        return cwd
    # Fallback: best-effort de-slug, last component only, no leading dash.
    return slug.lstrip("-").split("-")[-1] or "unknown"


def skim(path):
    """Single streaming pass over one transcript -> skim bundle dict."""
    slug = os.path.basename(os.path.dirname(path))
    session_id = os.path.splitext(os.path.basename(path))[0]
    cwd = ""
    msg_count = 0
    first_prompt = ""
    last_prompt = ""
    real_prompts = []
    first_command = ""  # fallback preview for command-initiated sessions

    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            typ = obj.get("type")
            if not cwd and obj.get("cwd"):
                cwd = obj["cwd"]
            if typ in ("user", "assistant"):
                msg_count += 1
            if typ != "user" or obj.get("isMeta"):
                continue
            txt = text_of(obj.get("message", {}))
            if not is_real_prompt(txt):
                if not first_command:
                    first_command = command_invocation(txt)
                continue
            t = trim(txt)
            if not first_prompt:
                first_prompt = t
            last_prompt = t
            real_prompts.append(t)

    # Command-initiated sessions have no typed prompt; show the command instead.
    if not first_prompt and first_command:
        first_prompt = trim(first_command)
        last_prompt = last_prompt or first_prompt

    # Evenly sample user turns across the conversation for ranking signal.
    sampled = []
    if real_prompts:
        n = min(MAX_SAMPLED_TURNS, len(real_prompts))
        step = max(1, len(real_prompts) // n)
        sampled = real_prompts[::step][:n]

    st = os.stat(path)
    mtime = dt.datetime.fromtimestamp(st.st_mtime)
    return {
        "session_id": session_id,
        "path": path,
        "project": project_name(cwd, slug),
        "cwd": cwd,
        "last_activity": mtime.isoformat(timespec="seconds"),
        "last_activity_date": mtime.strftime("%Y-%m-%d"),
        "size_bytes": st.st_size,
        "size_human": human_size(st.st_size),
        "message_count": msg_count,
        "first_prompt": first_prompt,
        "last_prompt": last_prompt,
        "sampled_turns": sampled,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--projects-dir", default=os.path.expanduser("~/.claude/projects"),
                    help="root of Claude Code project transcripts")
    ap.add_argument("--since", help="only convos active on/after this date (YYYY-MM-DD)")
    ap.add_argument("--project", help="only convos whose cwd contains this substring (case-insensitive)")
    ap.add_argument("--exclude-current", metavar="SESSION_ID",
                    help="drop this session id (the live session importing)")
    ap.add_argument("--limit", type=int, help="keep only the N most recent after filtering")
    ap.add_argument("--min-messages", type=int, default=0,
                    help="drop convos with fewer than N user+assistant messages")
    ap.add_argument("--out", help="write JSON here (creating parent dirs) instead of stdout")
    args = ap.parse_args()

    paths = glob.glob(os.path.join(args.projects_dir, "*", "*.jsonl"))
    rows = []
    for p in paths:
        try:
            rows.append(skim(p))
        except OSError as e:
            print(f"skip {p}: {e}", file=sys.stderr)

    if args.exclude_current:
        rows = [r for r in rows if r["session_id"] != args.exclude_current]
    if args.project:
        needle = args.project.lower()
        rows = [r for r in rows if needle in r["cwd"].lower()]
    if args.since:
        rows = [r for r in rows if r["last_activity_date"] >= args.since]
    if args.min_messages:
        rows = [r for r in rows if r["message_count"] >= args.min_messages]

    rows.sort(key=lambda r: r["last_activity"], reverse=True)
    if args.limit:
        rows = rows[: args.limit]

    print(f"indexed {len(rows)} conversations from {len(paths)} transcripts", file=sys.stderr)
    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w") as fh:
            json.dump(rows, fh, indent=2)
        print(f"wrote {args.out}", file=sys.stderr)
    else:
        json.dump(rows, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
