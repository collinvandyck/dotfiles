#!/usr/bin/env bats

# scripted-source-edit-check.sh is a PreToolUse hook on Bash. It reads the tool
# payload on stdin and, when a command would rewrite a tracked source file via a
# shell or interpreter script instead of the Edit/Write tools, returns an "ask"
# permission decision. Otherwise it exits silently. Each test feeds a real
# command string and asserts the side effect: the ask decision, or no output.
# The silent cases matter most -- a hook that questions every build and grep gets
# turned off within a day.

@test "asks for a python heredoc that reads and rewrites a go test file" {
	run_cmd "cd /Users/collin/code/temporal/saas-temporal && python3 - <<'PY'
import re
p='cds/service/history/queues/tiered_storage/executor_test.go'
s=open(p).read()
open(p,'w').write(re.sub('a','b',s))
PY"
	asks
}

@test "asks for sed -i, perl -pi, and ruby --in-place against source" {
	run_cmd "sed -i '' 's/foo/bar/' cds/service/history/task.go"
	asks
	run_cmd "perl -pi -e 's/foo/bar/' cds/config/dynamicconfig/development.yaml"
	asks
	run_cmd "ruby --in-place -e 'x' cds/foo.rb"
	asks
}

@test "asks for pathlib write_text, fileinput inplace, and node writeFileSync" {
	run_cmd "python3 -c \"from pathlib import Path; Path('cds/foo.go').write_text('x')\""
	asks
	run_cmd "python3 -c \"import fileinput; [print(l) for l in fileinput.input('cds/foo.go', inplace=True)]\""
	asks
	run_cmd "node -e \"require('fs').writeFileSync('web/app.ts','x')\""
	asks
}

@test "asks for a redirect or tee landing on a source file" {
	run_cmd "echo package main > cds/cmd/main.go"
	asks
	run_cmd "cat x | tee cds/foo.go"
	asks
}

@test "stays silent for reads, even when a source file is named" {
	run_cmd "python3 -c \"print(open('cds/foo.go').read())\""
	silent
	run_cmd "grep -n foo cds/service/history/task.go > /tmp/out"
	silent
	run_cmd "gofmt -l ./cds/service/history/"
	silent
}

@test "stays silent for builds and tests that write only to temp dirs" {
	run_cmd "go build -o /tmp/cds-admin ./cds/cmd/cds-admin"
	silent
	run_cmd "go test ./cds/... 2>&1 > /tmp/out.txt"
	silent
}

@test "stays silent for a python write into the session scratchpad" {
	run_cmd "python3 - <<'EOF'
open('/private/tmp/claude-501/x/scratchpad/notes.py','w').write('x')
EOF"
	silent
}

@test "stays silent for git, docker, and bare commands" {
	run_cmd "git checkout -- cds/service/history/task.go"
	silent
	run_cmd "docker exec temporal-dev-cassandra cqlsh -e \"SELECT tree_id FROM temporal.history_nodes\""
	silent
	run_cmd "ls"
	silent
}

@test "stays silent when the command field is absent" {
	run_hook '{"tool_name":"Bash","tool_input":{}}'
	silent
}

setup() {
	command -v jq >/dev/null 2>&1 || skip "jq not installed"
	HOOK="$BATS_TEST_DIRNAME/scripted-source-edit-check.sh"
}

# run_cmd COMMAND -> wrap a raw shell command in a Bash tool payload and feed it in.
run_cmd() {
	run_hook "$(jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}')"
}

# run_hook JSON -> feed JSON to the hook on stdin, capturing status/output.
run_hook() {
	printf '%s' "$1" >"$BATS_TEST_TMPDIR/input.json"
	run bash "$HOOK" <"$BATS_TEST_TMPDIR/input.json"
}

# asks -> the hook exited 0 and emitted an "ask" decision pointing back at Edit/Write.
asks() {
	[ "$status" -eq 0 ] || return 1
	printf '%s' "$output" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null || return 1
	printf '%s' "$output" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null || return 1
	printf '%s' "$output" | jq -e '.hookSpecificOutput.permissionDecisionReason | contains("Edit/Write")' >/dev/null
}

# silent -> the hook exited 0 with no output.
silent() {
	[ "$status" -eq 0 ] && [ -z "$output" ]
}
