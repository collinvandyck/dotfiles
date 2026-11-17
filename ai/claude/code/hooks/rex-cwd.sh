#!/bin/sh
# Records the session's current directory for the Rex pane it runs in, so Rex actions can open panes where the
# agent is working. Claude's process cwd never changes, but the hook input's cwd follows the agent's cd.
[ -n "$REX_BLOCK" ] || exit 0
dir="$HOME/.cache/rex-cwd"
mkdir -p "$dir" || exit 0
f="$dir/${REX_BLOCK#block:}"
jq -r '.cwd // empty' >"$f.tmp" && [ -s "$f.tmp" ] && mv "$f.tmp" "$f"
rm -f "$f.tmp"
exit 0
