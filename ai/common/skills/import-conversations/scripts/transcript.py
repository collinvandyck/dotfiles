#!/usr/bin/env python3
"""Shared transcript parsing: turn a Claude Code JSONL transcript into a clean,
readable list of turns. Used by serve_picker.py (drawer view) and
render_transcript.py (load into the current session). No LLM, local read only.
"""

import datetime as dt
import json
import os
import re

TRUNC = 600  # max chars kept per tool input / result
NOISE = ("<system-reminder", "<task-notification", "<bash-input",
         "<bash-stdout", "<local-command-stdout", "caveat:")


def trunc(s, n=TRUNC):
    s = (s or "").strip()
    return s if len(s) <= n else s[:n] + "…"


def command_invocation(text):
    """If text is a slash-command kickoff, render it as '/name args'; else ''."""
    if "<command-name>" not in text:
        return ""
    name = re.search(r"<command-name>(.*?)</command-name>", text, re.S)
    cargs = re.search(r"<command-args>(.*?)</command-args>", text, re.S)
    if not name:
        return ""
    parts = [name.group(1).strip()]
    if cargs and cargs.group(1).strip():
        parts.append(cargs.group(1).strip())
    return " ".join(parts)


def is_noise(s):
    low = s.strip().lower()
    return any(low.startswith(p) for p in NOISE)


def tool_input(inp):
    if isinstance(inp, dict):
        for k in ("command", "file_path", "path", "pattern", "query", "url", "prompt", "description"):
            if inp.get(k):
                return f"{k}: {inp[k]}"
        return json.dumps(inp)
    return str(inp) if inp is not None else ""


def result_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for b in content:
            if isinstance(b, dict):
                parts.append(b.get("text") or b.get("content") or "")
            else:
                parts.append(str(b))
        return " ".join(p for p in parts if p)
    return str(content) if content is not None else ""


def human_size(n):
    size = float(n)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            if unit == "B":
                return f"{int(size)}B"
            return f"{size:.1f}{unit}".replace(".0", "")
        size /= 1024
    return f"{size:.1f}GB"


def project_name(cwd):
    """Readable project label derived from cwd."""
    home = os.path.expanduser("~")
    if not cwd:
        return ""
    code = os.path.join(home, "code")
    if cwd.startswith(code + os.sep):
        return cwd[len(code) + 1:]
    if cwd.startswith(home + os.sep):
        return cwd[len(home) + 1:]
    return cwd


def parse_transcript(path):
    """Stream a JSONL transcript into a list of readable turns (balanced fidelity).

    Each turn: {role: user|assistant|tool, kind: text|command|tool_use|result, text, [tool]}.
    Tool inputs and results are truncated; raw JSON scaffolding is dropped.
    """
    turns = []
    cwd = ""
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not cwd and obj.get("cwd"):
                cwd = obj["cwd"]
            typ = obj.get("type")
            msg = obj.get("message", {}) or {}
            content = msg.get("content")
            if typ == "user" and not obj.get("isMeta"):
                if isinstance(content, str):
                    s = content.strip()
                    cmd = command_invocation(s)
                    if cmd:
                        turns.append({"role": "user", "kind": "command", "text": cmd})
                    elif s and not is_noise(s):
                        turns.append({"role": "user", "kind": "text", "text": s})
                elif isinstance(content, list):
                    txt = " ".join(b.get("text", "") for b in content
                                   if isinstance(b, dict) and b.get("type") == "text").strip()
                    if txt:
                        turns.append({"role": "user", "kind": "text", "text": txt})
                    for b in content:
                        if isinstance(b, dict) and b.get("type") == "tool_result":
                            turns.append({"role": "tool", "kind": "result",
                                          "text": trunc(result_text(b.get("content")))})
            elif typ == "assistant":
                if isinstance(content, str) and content.strip():
                    turns.append({"role": "assistant", "kind": "text", "text": content.strip()})
                elif isinstance(content, list):
                    for b in content:
                        if not isinstance(b, dict):
                            continue
                        bt = b.get("type")
                        if bt == "text" and b.get("text", "").strip():
                            turns.append({"role": "assistant", "kind": "text", "text": b["text"].strip()})
                        elif bt == "tool_use":
                            turns.append({"role": "assistant", "kind": "tool_use",
                                          "tool": b.get("name", ""), "text": trunc(tool_input(b.get("input")))})
    return turns, cwd


def meta(path, turns, cwd):
    """Header metadata for a rendered transcript."""
    st = os.stat(path)
    return {
        "project": project_name(cwd) or os.path.splitext(os.path.basename(path))[0],
        "date": dt.datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d"),
        "size_human": human_size(st.st_size),
        "turns": len(turns),
    }
