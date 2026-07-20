#!/bin/sh
# Remind the agent to consult the writing-mermaid-diagrams skill whenever it is
# about to write a mermaid diagram into a markdown file.
#
# Skill auto-triggering is driven by the skill's frontmatter description, which
# is only probabilistic -- it raises the odds, it does not guarantee the skill
# fires. This PreToolUse hook is the deterministic backstop: it inspects the
# text a Write/Edit/MultiEdit is about to commit and, when that text introduces
# a ```mermaid fence into a .md file, injects a reminder next to the tool call.
#
# It nudges, it does not enforce -- hooks cannot invoke a skill directly, only
# add context the agent then acts on.
#
# Known gap (intentional, to keep noise down): it fires on the text being
# written, so it catches a new or replaced diagram but not an edit that only
# touches the interior lines of a fence already on disk.

set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || true)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[ -n "$file_path" ] || exit 0

# Markdown targets only; the skill is about markdown-rendered diagrams.
case "$file_path" in
*.md | *.markdown | *.mdx) ;;
*) exit 0 ;;
esac

# Gather every chunk of incoming text across the write-shaped tools:
#   Write     -> .tool_input.content
#   Edit      -> .tool_input.new_string
#   MultiEdit -> .tool_input.edits[].new_string
incoming=$(printf '%s' "$input" | jq -r '
  [ .tool_input.content,
    .tool_input.new_string,
    (.tool_input.edits // [])[].new_string
  ] | map(select(. != null)) | join("\n")
' 2>/dev/null || true)
[ -n "$incoming" ] || exit 0

printf '%s' "$incoming" | grep -q '```mermaid' || exit 0

reminder='This write adds a ```mermaid diagram to a markdown file. Invoke the writing-mermaid-diagrams skill before finalizing it: line breaks in node and edge labels must use <br/>, never \n (which renders as a literal backslash-n on GitHub and Obsidian), and quotes, brackets, and pipes in label or note text need quoting/escaping.'

jq -n --arg ctx "$reminder" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
