#!/usr/bin/env bats

# ctt translates short aliases and injects context/duration before shelling out
# to omni. We stub omni on PATH so we can assert on the command line it receives.

setup() {
	STUB_DIR="$(mktemp -d)"
	cat > "$STUB_DIR/omni" <<-'EOF'
		#!/usr/bin/env sh
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
	[ "$output" = "omni kubectl -d 8h --context collin-cluster get pods" ]
}

@test "injects context for kubectl" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -d 8h --context collin-cluster get pods" ]
}

@test "injects context for k9s" {
	run "$BATS_TEST_DIRNAME/ctt" k9s
	[ "$status" -eq 0 ]
	[ "$output" = "omni k9s --context collin-cluster" ]
}

@test "does not inject context when one is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl --context other get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -d 8h --context other get pods" ]
}

@test "does not inject context for unsafe CT_CONTEXT" {
	export CT_CONTEXT="someone-else-cluster"
	run "$BATS_TEST_DIRNAME/ctt" kubectl get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl -d 8h get pods" ]
}

@test "injects default duration for kubectl" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl get pods
	[ "$status" -eq 0 ]
	[[ "$output" == *"kubectl -d 8h"* ]]
}

@test "injects default duration for access" {
	run "$BATS_TEST_DIRNAME/ctt" access aws
	[ "$status" -eq 0 ]
	[ "$output" = "omni access -d 8h aws" ]
}

@test "does not inject duration when -d is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kc -d 1h get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl --context collin-cluster -d 1h get pods" ]
}

@test "does not inject duration when --duration is already provided" {
	run "$BATS_TEST_DIRNAME/ctt" kubectl --duration 2h get pods
	[ "$status" -eq 0 ]
	[ "$output" = "omni kubectl --context collin-cluster --duration 2h get pods" ]
}

@test "does not inject duration for non-allowlisted commands" {
	run "$BATS_TEST_DIRNAME/ctt" k9s
	[ "$status" -eq 0 ]
	[[ "$output" != *"-d 8h"* ]]
}

@test "passes through non-allowlisted commands untouched" {
	run "$BATS_TEST_DIRNAME/ctt" foo bar
	[ "$status" -eq 0 ]
	[ "$output" = "omni foo bar" ]
}
