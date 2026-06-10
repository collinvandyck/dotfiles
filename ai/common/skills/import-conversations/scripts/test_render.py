#!/usr/bin/env python3
"""Tests for render_transcript.py — the balanced markdown render that gets
read straight into the current session.
"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "render_transcript.py")
FIXTURE = "/tmp/test_render_transcript.jsonl"

LINES = [
    {"type": "user", "cwd": "/Users/collin/code/temporal/cds",
     "message": {"content": "Hello, can you help with the watermark bug?"}},
    {"type": "assistant", "message": {"content": [
        {"type": "text", "text": "Sure -- let me look."},
        {"type": "tool_use", "name": "Bash", "input": {"command": "grep -r watermark"}}]}},
    {"type": "user", "message": {"content": [
        {"type": "tool_result", "content": "X" * 5000}]}},  # huge result -> must be truncated
    {"type": "assistant", "message": {"content": [{"type": "text", "text": "Here's the fix."}]}},
]


def run(*args):
    proc = subprocess.run([sys.executable, SCRIPT, *args], capture_output=True, text=True)
    if proc.returncode != 0:
        raise AssertionError(f"exit {proc.returncode}; stderr:\n{proc.stderr}")
    return proc.stdout


def check(name, cond, detail=""):
    if not cond:
        raise AssertionError(f"FAIL: {name} {detail}")
    print(f"ok: {name}")


def main():
    with open(FIXTURE, "w") as f:
        for rec in LINES:
            f.write(json.dumps(rec) + "\n")

    out = run(FIXTURE)
    check("renders a header with the project", "cds" in out)
    check("renders the user prompt", "watermark bug" in out)
    check("renders assistant text", "Here's the fix" in out)
    check("renders the tool call", "Bash" in out)
    check("truncates huge tool results", ("X" * 5000) not in out and "X" * 100 in out)

    # multiple transcripts in one invocation -> multiple headers
    out2 = run(FIXTURE, FIXTURE)
    check("renders each path given", out2.count("watermark bug") == 2)

    print("\nALL PASSED")


if __name__ == "__main__":
    main()
