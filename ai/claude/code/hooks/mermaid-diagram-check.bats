#!/usr/bin/env bats

# mermaid-diagram-check.sh is a PreToolUse hook. It reads the tool payload on
# stdin and, when a Write/Edit/MultiEdit is about to commit text containing a
# ```mermaid fence into a markdown file, prints a hookSpecificOutput reminder
# pointing at the writing-mermaid-diagrams skill. Otherwise it exits silently.
# Each test feeds a payload and asserts the real side effect: the reminder JSON,
# or no output at all.

@test "fires for a Write that adds a mermaid fence to a .md file" {
	run_hook '{"tool_name":"Write","tool_input":{"file_path":"/tmp/doc.md","content":"# T\n```mermaid\nflowchart TD\n A-->B\n```\n"}}'
	fired
}

@test "fires for an Edit whose new_string introduces a fence" {
	run_hook '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/doc.md","old_string":"foo","new_string":"```mermaid\nsequenceDiagram\n A->>B: hi\n```"}}'
	fired
}

@test "fires for a MultiEdit when any single edit adds a fence" {
	run_hook '{"tool_name":"MultiEdit","tool_input":{"file_path":"/tmp/doc.md","edits":[{"old_string":"a","new_string":"b"},{"old_string":"c","new_string":"```mermaid\ngraph LR\n```"}]}}'
	fired
}

@test "fires for .markdown and .mdx targets" {
	run_hook '{"tool_name":"Write","tool_input":{"file_path":"/tmp/doc.markdown","content":"```mermaid\ngraph TD\n```"}}'
	fired
	run_hook '{"tool_name":"Write","tool_input":{"file_path":"/tmp/doc.mdx","content":"```mermaid\ngraph TD\n```"}}'
	fired
}

@test "stays silent for a .md write with no mermaid fence" {
	run_hook '{"tool_name":"Write","tool_input":{"file_path":"/tmp/doc.md","content":"# Just prose, no diagram"}}'
	silent
}

@test "stays silent for a non-markdown file even when the text has a fence" {
	run_hook '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.go","content":"// ```mermaid\npackage x"}}'
	silent
}

@test "stays silent for an Edit whose new_string has no fence" {
	run_hook '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/doc.md","old_string":"foo","new_string":"bar baz"}}'
	silent
}

@test "stays silent when file_path is absent" {
	run_hook '{"tool_name":"Write","tool_input":{"content":"```mermaid\ngraph TD\n```"}}'
	silent
}

setup() {
	command -v jq >/dev/null 2>&1 || skip "jq not installed"
	HOOK="$BATS_TEST_DIRNAME/mermaid-diagram-check.sh"
}

# run_hook JSON -> feed JSON to the hook on stdin, capturing status/output.
run_hook() {
	printf '%s' "$1" >"$BATS_TEST_TMPDIR/input.json"
	run bash "$HOOK" <"$BATS_TEST_TMPDIR/input.json"
}

# fired -> the hook exited 0 and emitted a PreToolUse reminder naming the skill.
fired() {
	[ "$status" -eq 0 ] || return 1
	printf '%s' "$output" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null || return 1
	printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext | contains("writing-mermaid-diagrams")' >/dev/null
}

# silent -> the hook exited 0 with no output.
silent() {
	[ "$status" -eq 0 ] && [ -z "$output" ]
}
