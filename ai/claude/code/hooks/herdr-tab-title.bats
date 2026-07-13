#!/usr/bin/env bats

# herdr-tab-title.sh pushes Claude Code's session title onto the current herdr
# tab. It reads the hook JSON on stdin, pulls the latest title from the session
# transcript -- a custom /rename title wins over the auto-generated one -- and
# runs `herdr tab rename`. These tests stub `herdr` with a recorder on PATH and
# feed the hook temp transcripts, so each asserts the real side effect: the exact
# command the hook ran, or that it ran nothing.

@test "renames the tab to the ai-title when there is no custom title" {
	tp=$(seed_transcript \
		'{"type":"user","content":"hi"}' \
		'{"type":"ai-title","aiTitle":"check gocql pooling","sessionId":"s1"}')
	run_hook "{\"transcript_path\":\"$tp\"}"
	[ "$status" -eq 0 ]
	[ "$(cat "$HERDR_LOG")" = '[tab][rename][w9:tZ][check gocql pooling]' ]
}

@test "a custom title wins over the ai-title" {
	tp=$(seed_transcript \
		'{"type":"ai-title","aiTitle":"auto name","sessionId":"s1"}' \
		'{"type":"custom-title","customTitle":"my pinned name","sessionId":"s1"}')
	run_hook "{\"transcript_path\":\"$tp\"}"
	[ "$status" -eq 0 ]
	[ "$(cat "$HERDR_LOG")" = '[tab][rename][w9:tZ][my pinned name]' ]
}

@test "the latest title entry wins when several are present" {
	tp=$(seed_transcript \
		'{"type":"ai-title","aiTitle":"old topic","sessionId":"s1"}' \
		'{"type":"ai-title","aiTitle":"new topic","sessionId":"s1"}')
	run_hook "{\"transcript_path\":\"$tp\"}"
	[ "$(cat "$HERDR_LOG")" = '[tab][rename][w9:tZ][new topic]' ]
}

@test "does nothing when the transcript has no title yet" {
	tp=$(seed_transcript '{"type":"user","content":"hi"}')
	run_hook "{\"transcript_path\":\"$tp\"}"
	[ "$status" -eq 0 ]
	[ ! -s "$HERDR_LOG" ]
}

@test "does nothing when transcript_path is absent" {
	run_hook '{}'
	[ "$status" -eq 0 ]
	[ ! -s "$HERDR_LOG" ]
}

@test "does nothing when transcript_path points at a missing file" {
	run_hook "{\"transcript_path\":\"$BATS_TEST_TMPDIR/nope.jsonl\"}"
	[ "$status" -eq 0 ]
	[ ! -s "$HERDR_LOG" ]
}

@test "ignores subagent events (agent_id present)" {
	tp=$(seed_transcript '{"type":"ai-title","aiTitle":"sub work","sessionId":"s1"}')
	run_hook "{\"agent_id\":\"sub-1\",\"transcript_path\":\"$tp\"}"
	[ "$status" -eq 0 ]
	[ ! -s "$HERDR_LOG" ]
}

@test "is a no-op outside herdr (HERDR_ENV unset)" {
	unset HERDR_ENV
	tp=$(seed_transcript '{"type":"ai-title","aiTitle":"whatever","sessionId":"s1"}')
	run_hook "{\"transcript_path\":\"$tp\"}"
	[ "$status" -eq 0 ]
	[ ! -s "$HERDR_LOG" ]
}

@test "is a no-op when HERDR_TAB_ID is unset" {
	unset HERDR_TAB_ID
	tp=$(seed_transcript '{"type":"ai-title","aiTitle":"whatever","sessionId":"s1"}')
	run_hook "{\"transcript_path\":\"$tp\"}"
	[ "$status" -eq 0 ]
	[ ! -s "$HERDR_LOG" ]
}

setup() {
	command -v jq >/dev/null 2>&1 || skip "jq not installed"

	HOOK="$BATS_TEST_DIRNAME/herdr-tab-title.sh"
	export HERDR_LOG="$BATS_TEST_TMPDIR/herdr.log"

	# stub `herdr` with a recorder so we can assert the exact rename call.
	local bin="$BATS_TEST_TMPDIR/bin"
	mkdir -p "$bin"
	cat >"$bin/herdr" <<'STUB'
#!/bin/sh
{ for a in "$@"; do printf '[%s]' "$a"; done; printf '\n'; } >>"$HERDR_LOG"
STUB
	chmod +x "$bin/herdr"
	export PATH="$bin:$PATH"

	export HERDR_ENV=1
	export HERDR_TAB_ID="w9:tZ"
}

# seed_transcript LINE... -> write a transcript file, print its path.
seed_transcript() {
	local f="$BATS_TEST_TMPDIR/transcript.jsonl"
	printf '%s\n' "$@" >"$f"
	printf '%s' "$f"
}

# run_hook JSON -> feed JSON to the hook on stdin, capturing status/output.
run_hook() {
	printf '%s' "$1" >"$BATS_TEST_TMPDIR/input.json"
	run bash "$HOOK" <"$BATS_TEST_TMPDIR/input.json"
}
