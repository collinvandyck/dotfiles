#!/usr/bin/env bats

setup() {
	export FAKE_CLAUDE="$BATS_TEST_TMPDIR/fake-claude"
	printf '#!/usr/bin/env bash\nenv "$@"\n' >"$FAKE_CLAUDE"
	chmod +x "$FAKE_CLAUDE"
	export DS_CLAUDE_BIN=$FAKE_CLAUDE
	export DEEPSEEK_API_KEY=sk-test
}

@test "points claude at the deepseek endpoint" {
	run "$BATS_TEST_DIRNAME/ds"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic"* ]]
	[[ "$output" == *"ANTHROPIC_AUTH_TOKEN=sk-test"* ]]
}

@test "sets deepseek models and limits" {
	run "$BATS_TEST_DIRNAME/ds"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ANTHROPIC_MODEL=deepseek-flash[1m]"* ]]
	[[ "$output" == *"ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-flash[1m]"* ]]
	[[ "$output" == *"ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-flash[1m]"* ]]
	[[ "$output" == *"ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-flash"* ]]
	[[ "$output" == *"CLAUDE_CODE_SUBAGENT_MODEL=deepseek-flash"* ]]
	[[ "$output" == *"CLAUDE_CODE_EFFORT_LEVEL=max"* ]]
	[[ "$output" == *"CLAUDE_CODE_AUTO_COMPACT_WINDOW=786432"* ]]
}

@test "drops an anthropic api key so the auth token wins" {
	ANTHROPIC_API_KEY=sk-ant run "$BATS_TEST_DIRNAME/ds"
	[ "$status" -eq 0 ]
	[[ "$output" != *"ANTHROPIC_API_KEY="* ]]
}

@test "fails when the deepseek key is missing" {
	unset DEEPSEEK_API_KEY
	run "$BATS_TEST_DIRNAME/ds"
	[ "$status" -ne 0 ]
	[[ "$output" == *"DEEPSEEK_API_KEY is not set"* ]]
}

@test "passes arguments through to claude" {
	printf '#!/usr/bin/env bash\nprintf "%%s\\\\n" "$@"\n' >"$FAKE_CLAUDE"
	run "$BATS_TEST_DIRNAME/ds" --resume --model opus
	[ "$status" -eq 0 ]
	[ "$output" = "--resume
--model
opus" ]
}
