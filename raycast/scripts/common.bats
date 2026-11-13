#!/usr/bin/env bats

setup() {
	STUB_DIR="$(mktemp -d)"
	HOME="$STUB_DIR/home"
	mkdir -p "$HOME"
	export HOME

	# Stands in for a raycast script: resolves the cell, prints it, and exits
	# with the status given as the second argument.
	cat >"$STUB_DIR/run.sh" <<-EOF
		#!/usr/bin/env bash
		. "$BATS_TEST_DIRNAME/common.sh"
		use_cell "\$1"
		printf '%s\n' "\$CELL"
		exit "\${2:-0}"
	EOF
	chmod +x "$STUB_DIR/run.sh"

	# Records the urls open_grafana hands to `open` instead of launching them.
	OPEN_LOG="$STUB_DIR/open.log"
	cat >"$STUB_DIR/open" <<-'EOF'
		#!/usr/bin/env sh
		printf '%s\n' "$1" >> "$OPEN_LOG"
	EOF
	chmod +x "$STUB_DIR/open"
	PATH="$STUB_DIR:$PATH"
	export OPEN_LOG
}

teardown() {
	rm -rf "$STUB_DIR"
}

last_cell() {
	cat "$HOME/.last-cell"
}

write_env() {
	cat >"$HOME/.env" <<-'EOF'
		GRAFANA_HOST=grafana.example
		TEMPORAL_CP_NAMESPACE=prod.cp
		TEMPORAL_TEST_CP_NAMESPACE=test.cp
		TEMPORAL_INFRA_NAMESPACE=prod.infra
		TEMPORAL_TEST_INFRA_NAMESPACE=test.infra
	EOF
}

@test "normalizes the cell and remembers it" {
	run "$STUB_DIR/run.sh" "aw021"
	[ "$status" -eq 0 ]
	[ "$output" = "s-aw021" ]

	run last_cell
	[ "$output" = "s-aw021" ]
}

@test "leaves an already-prefixed cell alone and trims whitespace" {
	run "$STUB_DIR/run.sh" "  s-aw021  "
	[ "$status" -eq 0 ]
	[ "$output" = "s-aw021" ]
}

@test "falls back to the remembered cell when the argument is empty" {
	printf '%s\n' "s-aw028" >"$HOME/.last-cell"

	run "$STUB_DIR/run.sh" ""
	[ "$status" -eq 0 ]
	[ "$output" = "s-aw028" ]
}

@test "normalizes what it reads back from a hand-edited file" {
	printf '%s\n' "aw028" >"$HOME/.last-cell"

	run "$STUB_DIR/run.sh" ""
	[ "$status" -eq 0 ]
	[ "$output" = "s-aw028" ]
}

@test "does not remember the cell when the script fails" {
	printf '%s\n' "s-aw028" >"$HOME/.last-cell"

	run "$STUB_DIR/run.sh" "aw021" 1
	[ "$status" -eq 1 ]

	run last_cell
	[ "$output" = "s-aw028" ]
}

@test "fails when no cell is given and none is remembered" {
	run "$STUB_DIR/run.sh" ""
	[ "$status" -eq 1 ]
	[[ "$output" == *"Cell required"* ]]
	[ ! -f "$HOME/.last-cell" ]
}

@test "staging remembers its cell apart from the prod cell" {
	printf '%s\n' "s-aw028" >"$HOME/.last-cell"

	run env CELL_PROFILE=staging "$STUB_DIR/run.sh" "cds-collin-261109"
	[ "$status" -eq 0 ]
	[ "$output" = "s-cds-collin-261109" ]

	run cat "$HOME/.last-staging-cell"
	[ "$output" = "s-cds-collin-261109" ]
	run last_cell
	[ "$output" = "s-aw028" ]
}

@test "staging ignores the remembered prod cell" {
	printf '%s\n' "s-aw028" >"$HOME/.last-cell"
	printf '%s\n' "s-cds-collin-261109" >"$HOME/.last-staging-cell"

	run env CELL_PROFILE=staging "$STUB_DIR/run.sh" ""
	[ "$status" -eq 0 ]
	[ "$output" = "s-cds-collin-261109" ]
}

@test "staging falls back to CELL in ~/.envrc when nothing is remembered" {
	printf 'source_up\nexport CELL=s-cds-collin-261026\n' >"$HOME/.envrc"

	run env CELL_PROFILE=staging "$STUB_DIR/run.sh" ""
	[ "$status" -eq 0 ]
	[ "$output" = "s-cds-collin-261026" ]
}

@test "staging prefers the remembered staging cell over ~/.envrc" {
	printf 'export CELL=s-cds-collin-261026\n' >"$HOME/.envrc"
	printf '%s\n' "s-cds-collin-261109" >"$HOME/.last-staging-cell"

	run env CELL_PROFILE=staging "$STUB_DIR/run.sh" ""
	[ "$status" -eq 0 ]
	[ "$output" = "s-cds-collin-261109" ]
}

@test "the prod history script opens the prod datasources" {
	write_env

	run "$BATS_TEST_DIRNAME/open-cell-history.sh" "aw021"
	[ "$status" -eq 0 ]

	run cat "$OPEN_LOG"
	[[ "$output" == *"var-env=prod&"* ]]
	[[ "$output" == *"var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&"* ]]
	[[ "$output" == *"var-cluster=s-aw021&"* ]]
}

@test "the staging history script opens the test datasources" {
	write_env

	run "$BATS_TEST_DIRNAME/staging-cell-history.sh" "cds-collin-261109"
	[ "$status" -eq 0 ]

	run cat "$OPEN_LOG"
	[[ "$output" == *"var-env=dev%20thanos&"* ]]
	[[ "$output" == *"var-datasource=ef667c0e-d08c-4b40-9761-479514828632&"* ]]
	[[ "$output" == *"var-clickhouse_datasource=bevsfyywc7hfka&"* ]]
	[[ "$output" == *"var-cluster=s-cds-collin-261109&"* ]]
}

@test "the staging workflows script opens only the test namespaces" {
	write_env

	run "$BATS_TEST_DIRNAME/staging-cell-workflows.sh" "cds-collin-261109"
	[ "$status" -eq 0 ]

	run cat "$OPEN_LOG"
	[ "${#lines[@]}" -eq 2 ]
	[[ "${lines[0]}" == "https://cloud.temporal.io/namespaces/test.cp/workflows?"* ]]
	[[ "${lines[1]}" == "https://cloud.temporal.io/namespaces/test.infra/workflows?"* ]]
}

@test "the staging support page opens on thundergun" {
	run "$BATS_TEST_DIRNAME/open-staging-cell.sh" "cds-collin-261109"
	[ "$status" -eq 0 ]

	run cat "$OPEN_LOG"
	[ "$output" = "https://staging.thundergun.io/support/cells/s-cds-collin-261109" ]
}

@test "open_grafana appends a 1m refresh to a url with a query string" {
	run bash -c ". '$BATS_TEST_DIRNAME/common.sh'; open_grafana 'https://g.example/d/x?orgId=1'"
	[ "$status" -eq 0 ]

	run cat "$OPEN_LOG"
	[ "$output" = "https://g.example/d/x?orgId=1&refresh=1m" ]
}

@test "open_grafana starts the query string when the url has none" {
	run bash -c ". '$BATS_TEST_DIRNAME/common.sh'; open_grafana 'https://g.example/d/x'"
	[ "$status" -eq 0 ]

	run cat "$OPEN_LOG"
	[ "$output" = "https://g.example/d/x?refresh=1m" ]
}
