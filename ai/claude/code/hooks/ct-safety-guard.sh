#!/bin/sh
# Deny ct/ocld commands that skip a safety check unless they target only my test cells, and deny prod outright.
#
# CLAUDE.md already says this, but it only works when the agent remembers it. Flags such as --skip-approval and
# --skip-confirmation remove the last human check before a rollout, so a slip reaches real cells. This hook checks every
# Bash call, including the ones made after compaction or by a subagent.
#
# The hook sees the command before the shell expands it, so it fails closed. A cell given as a variable, a glob, a ring
# flag, or no cell at all is denied whenever a skip flag is present. Write the s-cds-collin or s-collin- cell names out
# literally.

set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || true)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -n "$cmd" ] || exit 0

deny() {
	jq -n --arg reason "$1" '{
		hookSpecificOutput: {
			hookEventName: "PreToolUse",
			permissionDecision: "deny",
			permissionDecisionReason: $reason
		}
	}'
	exit 0
}

# A DestroyVisibilityStore-style workflow input that skips approvals must name one of my cells.
if printf '%s' "$cmd" | grep -qiE '"SkipApprovals"[[:space:]]*:[[:space:]]*true'; then
	if ! printf '%s' "$cmd" | grep -qE '"ID"[[:space:]]*:[[:space:]]*"(s-cds-collin|s-collin-)'; then
		deny "ct-safety-guard: SkipApprovals is only allowed when the input's cell ID starts with s-cds-collin or s-collin-."
	fi
fi

# Everything below is about ct and ocld invocations.
printf '%s' "$cmd" | grep -qE '(^|[;&|(`[:space:]])(ct|ocld)[[:space:]]' || exit 0

if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])ocld[[:space:]]+prod([[:space:]]|$)'; then
	deny "ct-safety-guard: never run ct/ocld commands against the prod environment."
fi

SKIP_FLAGS='(^|[[:space:]])(--skip-approval|--skip-confirmation|--skip-prompts|--skip|--allow-any-time)([[:space:]=]|$)|--mode([[:space:]]+|=)["'"'"']?(emergency|breakglass)'
printf '%s' "$cmd" | grep -qE "$SKIP_FLAGS" || exit 0

if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])(-r|--ring|--ring-allow)([[:space:]]|=)'; then
	deny "ct-safety-guard: skip flags can't be combined with a ring selector. Name s-cds-collin or s-collin- cells with -c instead."
fi

cells=$(printf '%s\n' "$cmd" |
	grep -oE '(^|[[:space:]])(-c|--cell|--cell-allow|--allow|--cell-id)([[:space:]]+|=)[^[:space:];|&)]+' |
	sed -E 's/^[[:space:]]*(-c|--cell|--cell-allow|--allow|--cell-id)([[:space:]]+|=)//' |
	tr -d "\"'")

if [ -z "$cells" ]; then
	deny "ct-safety-guard: skip flags need an explicit cell. Pass -c with a literal s-cds-collin or s-collin- cell name."
fi

for c in $cells; do
	case "$c" in
	s-cds-collin* | s-collin-*) ;;
	*) deny "ct-safety-guard: skip flags are only allowed on s-cds-collin and s-collin- cells, and $c isn't one." ;;
	esac
	if printf '%s' "$c" | grep -qE '[][*?$`{}]'; then
		deny "ct-safety-guard: skip flags need literal cell names, not a glob or variable ($c)."
	fi
done

exit 0
