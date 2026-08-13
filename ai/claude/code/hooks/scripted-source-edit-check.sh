#!/bin/sh
# Route shell-scripted rewrites of source files back to the Edit/Write tools.
#
# The failure mode this catches: given N near-identical sites to change, Edit costs N calls (each needing a unique
# old_string), while one regex costs one call. The agent optimizes for call count and hand-rolls a python heredoc that
# opens the file and rewrites it. That looks cheaper and usually isn't -- a bad regex over real syntax succeeds and
# produces wrong code, so the loop becomes write, inspect, git checkout, rewrite. Edit either applies exactly or errors.
#
# So this asks instead of denying. CLAUDE.md says to strongly prefer Edit/Write "unless the situation calls for it", and
# a hard block would delete that escape hatch -- a genuine 200-file mechanical rename is a real case. One keystroke of
# friction is enough to make the cheap-looking path stop being the free one.
#
# It fires only when the command both uses a file-mutating idiom AND names a source file outside scratch space, so
# reading files, writing to /tmp or the session scratchpad, and building into a temp dir all pass through untouched.

set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || true)

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -n "$cmd" ] || exit 0

# Extensions worth protecting: anything a human maintains by hand. Deliberately includes config and markdown -- Write is
# the right tool for those too.
EXT='go|py|rs|ts|tsx|js|jsx|mjs|cjs|java|rb|sh|bash|zsh|lua|proto|sql|tf|tfvars|yaml|yml|json|toml|md|c|h|cc|cpp|hpp|vue|svelte|php|cs|kt|swift'

# Scratch space is fair game -- /tmp, the per-session scratchpad, macOS mkstemp dirs, Downloads, /dev/null.
SCRATCH='^(/private)?/tmp/|/scratchpad/|^/var/folders/|/Downloads/|^/dev/'

targets=$(printf '%s\n' "$cmd" |
	grep -oE "[A-Za-z0-9_./~-]+\.($EXT)([^A-Za-z0-9]|$)" 2>/dev/null |
	sed 's/[^A-Za-z0-9]$//' |
	grep -vE "$SCRATCH" |
	sort -u)
[ -n "$targets" ] || exit 0

idiom=''

# sed/perl/ruby -i: in-place by definition, so naming a source file is enough.
if printf '%s' "$cmd" | grep -qE '(^|[;&|(]|[[:space:]])(sed|perl|ruby)[[:space:]]+(-[A-Za-z]*i|--in-place)'; then
	idiom='an in-place -i rewrite'
fi

# An interpreter plus a write call. Bare open()/read() is a read and does not match.
if [ -z "$idiom" ] &&
	printf '%s' "$cmd" | grep -qE '(^|[;&|(]|[[:space:]])(python3?|perl|ruby|node|deno|bun)([[:space:]]|$)' &&
	printf '%s' "$cmd" | grep -qE "open\([^)]*,[[:space:]]*['\"][wax]|\.write(lines)?\(|write_text\(|writeFileSync|fileinput\.input\([^)]*inplace"; then
	idiom='an interpreter script that writes the file'
fi

# A redirect or tee landing directly on a source file. Requires the *target* to be a source file, so
# `grep foo bar.go > /tmp/out` stays quiet.
if [ -z "$idiom" ] &&
	printf '%s' "$cmd" | grep -qE ">>?[[:space:]]*[A-Za-z0-9_./~-]+\.($EXT)([^A-Za-z0-9]|$)|(^|[[:space:]])tee([[:space:]]+-a)?[[:space:]]+[A-Za-z0-9_./~-]+\.($EXT)([^A-Za-z0-9]|$)"; then
	idiom='a shell redirect onto the file'
fi

[ -n "$idiom" ] || exit 0

files=$(printf '%s' "$targets" | tr '\n' ' ' | sed 's/ $//')

reason="This command rewrites tracked source files ($files) using $idiom. CLAUDE.md says to strongly prefer the Edit/Write tools over one-off shell or python scripts. For many near-identical sites, use one Edit per site with enough surrounding context to make each old_string unique, or replace_all when the substitution really is global -- N deterministic edits beat one regex that has to be verified and often reverted. If this genuinely is the case that calls for a script (a large mechanical rename across many files, or a transform Edit cannot express), say why and it can be approved."

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $reason
  }
}'
