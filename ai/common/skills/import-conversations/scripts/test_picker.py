#!/usr/bin/env python3
"""Headless test for serve_picker.py.

Starts the picker with --no-open on a known port, fetches the page, simulates
the browser POST (both 'import' and 'refine'), and asserts the script prints
the right JSON to stdout and exits 0.
"""

import json
import os
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "serve_picker.py")
PORT = 8743

FIXTURE = "/tmp/test_picker_transcript.jsonl"

CANDIDATES = {
    "query": "watermark work",
    "candidates": [
        {"session_id": "aaaa1111", "path": "/tmp/a.jsonl", "project": "temporal/saas-temporal",
         "last_activity": "2026-06-09T10:00:00", "last_activity_date": "2026-06-09",
         "size_bytes": 5347737, "size_human": "5.1MB", "message_count": 120,
         "preview": "Replay gameday: investigated watermark gaps, landed a fix."},
        {"session_id": "bbbb2222", "path": "/tmp/b.jsonl", "project": "temporal/boss-proxy",
         "last_activity": "2026-06-05T09:00:00", "last_activity_date": "2026-06-05",
         "size_bytes": 307200, "size_human": "300KB", "message_count": 40,
         "preview": "gRPC retry semantics between history and bookkeeper."},
        {"session_id": "cccc3333", "path": FIXTURE, "project": "temporal/cds",
         "last_activity": "2026-06-07T12:00:00", "last_activity_date": "2026-06-07",
         "size_bytes": 2048, "size_human": "2KB", "message_count": 4,
         "preview": "Small fixture conversation for the transcript view."},
    ],
}

FIXTURE_LINES = [
    {"type": "user", "message": {"content": "Hello, can you help with the watermark bug?"}},
    {"type": "assistant", "message": {"content": [
        {"type": "text", "text": "Sure -- let me look."},
        {"type": "tool_use", "name": "Bash", "input": {"command": "grep -r watermark"}}]}},
    {"type": "user", "message": {"content": [
        {"type": "tool_result", "content": "found 3 matches"}]}},
    {"type": "assistant", "message": {"content": [{"type": "text", "text": "Here's the fix."}]}},
]


def start(cand_path):
    proc = subprocess.Popen(
        [sys.executable, SCRIPT, cand_path, "--no-open", "--port", str(PORT)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    # wait for the server to come up
    for _ in range(50):
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{PORT}/", timeout=1).read()
            return proc
        except Exception:
            time.sleep(0.1)
    out, err = proc.communicate(timeout=5)
    raise AssertionError(f"server never came up. stderr:\n{err}")


def post(payload):
    req = urllib.request.Request(
        f"http://127.0.0.1:{PORT}/submit",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    return urllib.request.urlopen(req, timeout=5).read()


def check(name, cond, detail=""):
    if not cond:
        raise AssertionError(f"FAIL: {name} {detail}")
    print(f"ok: {name}")


def get_json(path):
    return json.loads(urllib.request.urlopen(f"http://127.0.0.1:{PORT}{path}", timeout=5).read())


def main():
    cand_path = "/tmp/test_picker_candidates.json"
    with open(cand_path, "w") as f:
        json.dump(CANDIDATES, f)
    with open(FIXTURE, "w") as f:
        for rec in FIXTURE_LINES:
            f.write(json.dumps(rec) + "\n")

    # --- case 1: page renders, shows previews, sort control, transcript hook ---
    proc = start(cand_path)
    try:
        html = urllib.request.urlopen(f"http://127.0.0.1:{PORT}/", timeout=2).read().decode()
        check("page renders", "<html" in html.lower())
        check("page embeds a preview", "watermark gaps" in html)
        check("page shows project", "boss-proxy" in html)
        check("page has a sort control", 'id="sort"' in html)
        check("page offers recency sort", "Recent" in html or "recent" in html)
        check("page wires up the transcript view", "/transcript" in html)

        # --- transcript endpoint parses a real jsonl into readable turns ---
        tr = get_json("/transcript?id=cccc3333")
        turns = tr.get("turns", [])
        check("transcript returns turns", isinstance(turns, list) and len(turns) >= 3)
        joined = " ".join(t.get("text", "") for t in turns)
        check("transcript has the user prompt", "watermark bug" in joined)
        check("transcript has assistant text", "Here's the fix" in joined)
        check("transcript surfaces tool use",
              any(t.get("kind") == "tool_use" and t.get("tool") == "Bash" for t in turns))

        # --- case 1 (cont): simulate selecting one card and importing ---
        post({"selected": ["aaaa1111"]})
        out, err = proc.communicate(timeout=5)
        check("import exits 0", proc.returncode == 0, err)
        result = json.loads(out)
        check("import returns selected list", isinstance(result.get("selected"), list))
        check("import returns one item", len(result["selected"]) == 1)
        check("import maps id -> full object", result["selected"][0]["path"] == "/tmp/a.jsonl")
    finally:
        if proc.poll() is None:
            proc.kill()

    # --- case 2: refine action ---
    proc = start(cand_path)
    try:
        post({"action": "refine", "query": "look for the cassandra ring stuff"})
        out, err = proc.communicate(timeout=5)
        check("refine exits 0", proc.returncode == 0, err)
        result = json.loads(out)
        check("refine action returned", result.get("action") == "refine")
        check("refine carries query", "cassandra" in result.get("query", ""))
    finally:
        if proc.poll() is None:
            proc.kill()

    print("\nALL PASSED")


if __name__ == "__main__":
    main()
