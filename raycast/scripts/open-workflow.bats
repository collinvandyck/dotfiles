#!/usr/bin/env bats

setup() {
	STUB_DIR="$(mktemp -d)"
	HOME="$STUB_DIR/home"
	OPEN_LOG="$STUB_DIR/open.log"
	PBPASTE_VALUE="$STUB_DIR/pbpaste-value"
	mkdir -p "$HOME"

	cat >"$STUB_DIR/open" <<-'EOF'
		#!/usr/bin/env sh
		printf '%s\n' "$1" >> "$OPEN_LOG"
	EOF
	chmod +x "$STUB_DIR/open"

	cat >"$STUB_DIR/pbpaste" <<-'EOF'
		#!/usr/bin/env sh
		if [ -f "$PBPASTE_VALUE" ]; then
			cat "$PBPASTE_VALUE"
		fi
	EOF
	chmod +x "$STUB_DIR/pbpaste"

	PATH="$STUB_DIR:$PATH"
	export HOME OPEN_LOG PBPASTE_VALUE
}

teardown() {
	rm -rf "$STUB_DIR"
}

opened_url() {
	cat "$OPEN_LOG"
}

@test "opens the selected namespace and percent-encoded workflow id" {
	run "$BATS_TEST_DIRNAME/open-workflow.sh" "scaffold.infra" "scaffold-v1/DestroyCellTestEnvironment/aws/test-b8kbzvuuakyegfgt4fgp643b8/us-central1/s-cds-collin-0710-gcp"
	[ "$status" -eq 0 ]

	run opened_url
	[ "$output" = "https://cloud.temporal.io/namespaces/scaffold.infra/workflows/scaffold-v1%2FDestroyCellTestEnvironment%2Faws%2Ftest-b8kbzvuuakyegfgt4fgp643b8%2Fus-central1%2Fs-cds-collin-0710-gcp" ]
}

@test "uses the clipboard when workflow id argument is empty" {
	printf '%s\n' "workflow/from/clipboard" >"$PBPASTE_VALUE"

	run "$BATS_TEST_DIRNAME/open-workflow.sh" "scaffold.infra" ""
	[ "$status" -eq 0 ]

	run opened_url
	[ "$output" = "https://cloud.temporal.io/namespaces/scaffold.infra/workflows/workflow%2Ffrom%2Fclipboard" ]
}

@test "dropdown metadata uses literal namespace values" {
	run grep '^# @raycast.argument1' "$BATS_TEST_DIRNAME/open-workflow.sh"
	[ "$status" -eq 0 ]

	[[ "$output" == *'"value": "scaffold.infra"'* ]]
	[[ "$output" == *'"value": "prod.infra"'* ]]
	[[ "$output" == *'"value": "prod.cp"'* ]]
	[[ "$output" == *'"value": "test.cp"'* ]]
	[[ "$output" != *"TEMPORAL_"* ]]
}

@test "fails when no workflow id is provided by argument or clipboard" {
	run "$BATS_TEST_DIRNAME/open-workflow.sh" "scaffold.infra" ""
	[ "$status" -eq 1 ]
	[ "$output" = "Workflow ID required" ]
	[ ! -f "$OPEN_LOG" ]
}
