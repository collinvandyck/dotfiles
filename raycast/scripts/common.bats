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
