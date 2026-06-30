#!/usr/bin/env bats

# ctt translates short aliases and injects context/duration before shelling out
# to omni. We stub omni on PATH so we can assert on the command line it receives.

setup() {
	STUB_DIR="$(mktemp -d)"
	cat > "$STUB_DIR/omni" <<-'EOF'
		#!/usr/bin/env sh
		# record that omni actually ran, so dry-run tests can assert it didn't
		touch "$(dirname "$0")/ran"
		printf 'omni %s\n' "$*"
	EOF
	chmod +x "$STUB_DIR/omni"
	PATH="$STUB_DIR:$PATH"

	# a safe-pattern context so injection is enabled
	export CT_CONTEXT="collin-cluster"
}

teardown() {
	rm -rf "$STUB_DIR"
}

@test "kc expands to kubectl" {
	run "$BATS_TEST_DIRNAME/ctt" kc get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -n temporal -d 8h --context collin-cluster get pods" ]
}

@test "injects context, duration, and namespace for kubectl" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -n temporal -d 8h --context collin-cluster get pods" ]
}

@test "injects context only for admintools" {
	run "$BATS_TEST_DIRNAME/ctt" admintools
	[ "$status" -eq 0 ]
	[ "$output" = "omni admintools --context collin-cluster" ]
}

@test "injects context, duration, namespace, and write for k9s on own cell" {
	run "$BATS_TEST_DIRNAME/ctt" k9s
	[ "$status" -eq 0 ]
	[ "$output" = "omni k9s --write -n temporal -d 8h --context collin-cluster" ]
}

@test "injects write for k9s when own cell is given explicitly via --context" {
	run "$BATS_TEST_DIRNAME/ctt" k9s --context collin-cluster
	[ "$status" -eq 0 ]
	[[ "$output" == *"--write"* ]]
}

@test "does not inject write for k9s targeting another cell via -c" {
	run "$BATS_TEST_DIRNAME/ctt" k9s -c other-cell
	[ "$status" -eq 0 ]
	[[ "$output" != *"--write"* ]]
}

@test "does not double-inject context for k9s when -c is provided" {
	run "$BATS_TEST_DIRNAME/ctt" k9s -c other-cell
	[ "$status" -eq 0 ]
	[[ "$output" != *"--context"* ]]
}

@test "does not inject context when one is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl --context other get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -n temporal -d 8h --context other get pods" ]
}

@test "does not inject context for unsafe CT_CONTEXT" {
	export CT_CONTEXT="someone-else-cluster"
	run "$BATS_TEST_DIRNAME/ctt" kubectl get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -n temporal -d 8h get pods" ]
}

@test "injects default duration for kubectl" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl get pods
	[ "$status" -eq 0 ]
	[[ "$output" == *"-d 8h"* ]]
}

@test "does not inject namespace when one is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl -n kube-system get pods
	[ "$status" -eq 0 ]
	[[ "$output" != *"-n temporal"* ]]
	[[ "$output" == *"-n kube-system"* ]]
}

@test "injects default duration for access" {
	run "$BATS_TEST_DIRNAME/ctt" access aws
	[ "$status" -eq 0 ]
	[ "$output" = "omni access -d 8h aws" ]
}

@test "does not inject duration when -d is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kc -d 1h get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -n temporal --context collin-cluster -d 1h get pods" ]
}

@test "does not inject duration when --duration is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl --duration 2h get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -n temporal --context collin-cluster --duration 2h get pods" ]
}

@test "does not inject duration for non-allowlisted commands" {
	run "$BATS_TEST_DIRNAME/ctt" foo bar
	[ "$status" -eq 0 ]
	[[ "$output" != *"-d 8h"* ]]
}

@test "passes through non-allowlisted commands untouched" {
	run "$BATS_TEST_DIRNAME/ctt" foo bar
	[ "$status" -eq 0 ]
	[ "$output" = "omni foo bar" ]
}

@test "--dry-run prints the resolved command without running omni" {
	# the stub writes a marker file when invoked; dry-run must not trigger it
	run "$BATS_TEST_DIRNAME/ctt" --dry-run k9s
	[ "$status" -eq 0 ]
	# only the dry-run echo is emitted, and --dry-run itself is stripped
	[ "${#lines[@]}" -eq 1 ]
	[ "$output" = "omni k9s --write -n temporal -d 8h --context collin-cluster" ]
	[[ "$output" != *"--dry-run"* ]]
}

@test "--dry-run does not execute omni" {
	run "$BATS_TEST_DIRNAME/ctt" --dry-run foo bar
	[ "$status" -eq 0 ]
	[ ! -f "$STUB_DIR/ran" ]
}

@test "--dry-run is accepted when not the first argument" {
	run "$BATS_TEST_DIRNAME/ctt" foo --dry-run bar
	[ "$status" -eq 0 ]
	[ "$output" = "omni foo bar" ]
}
