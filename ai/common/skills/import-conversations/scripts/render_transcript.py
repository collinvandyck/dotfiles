#!/usr/bin/env python3
"""Render one or more Claude Code transcripts as balanced markdown to stdout.

The main session runs this and reads the output straight into its own context —
this is the "import" step. Balanced fidelity: user + assistant prose, condensed
tool calls, truncated tool results, no raw JSON scaffolding. Local read, no LLM.

    render_transcript.py <transcript.jsonl> [<transcript.jsonl> ...]
"""

import sys

from transcript import meta, parse_transcript  # pyright: ignore[reportMissingImports]  (sibling script)

ROLE_LINE = {
    ("user", "text"): "**You:** {text}",
    ("user", "command"): "**You** ran `{text}`",
    ("assistant", "text"): "**Claude:** {text}",
    ("tool", "result"): "← {text}",
}


def render(path):
    turns, cwd = parse_transcript(path)
    m = meta(path, turns, cwd)
    out = [f"# {m['project']} — {m['date']}  ({m['size_human']}, {m['turns']} turns)", ""]
    for t in turns:
        if t["kind"] == "tool_use":
            out.append(f"→ `{t.get('tool','tool')}`: {t['text']}")
        else:
            tmpl = ROLE_LINE.get((t["role"], t["kind"]), "{text}")
            out.append(tmpl.format(text=t["text"]))
        out.append("")
    return "\n".join(out)


def main():
    paths = sys.argv[1:]
    if not paths:
        print("usage: render_transcript.py <transcript.jsonl> [...]", file=sys.stderr)
        sys.exit(2)
    blocks = []
    for path in paths:
        try:
            blocks.append(render(path))
        except OSError as e:
            blocks.append(f"# (could not read {path}: {e})")
    print("\n\n---\n\n".join(blocks))
    print(f"rendered {len(paths)} transcript(s)", file=sys.stderr)


if __name__ == "__main__":
    main()
