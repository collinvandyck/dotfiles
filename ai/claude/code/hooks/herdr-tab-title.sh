#!/bin/sh
# Sync the herdr tab label to Claude Code's session title.
#
# Companion to the herdr-managed herdr-agent-state.sh -- do NOT fold this into
# that file; herdr overwrites it on reinstall. This one is ours.
#
# No Claude hook fires on /rename, so we read the title Claude persists to the
# transcript (custom title wins over the auto-generated one) and push it to the
# current herdr tab. Wired to SessionStart, UserPromptSubmit, and Stop, the tab
# follows /rename with at most a one-turn lag. Outside herdr it is a no-op.

set -u

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_TAB_ID:-}" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

herdr_bin=$(command -v herdr 2>/dev/null || printf '%s' /opt/homebrew/bin/herdr)
[ -x "$herdr_bin" ] || exit 0

input=$(cat 2>/dev/null || true)

# Only the main session names the tab; skip subagent events.
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null || true)
[ -z "$agent_id" ] || exit 0

tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

title=$(grep '"type":"custom-title"' "$tp" 2>/dev/null | tail -1 | jq -r '.customTitle // empty' 2>/dev/null || true)
if [ -z "$title" ]; then
	title=$(grep '"type":"ai-title"' "$tp" 2>/dev/null | tail -1 | jq -r '.aiTitle // empty' 2>/dev/null || true)
fi
[ -n "$title" ] || exit 0

"$herdr_bin" tab rename "$HERDR_TAB_ID" "$title" >/dev/null 2>&1 || true
