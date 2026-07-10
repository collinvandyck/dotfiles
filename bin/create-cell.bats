#!/usr/bin/env bats

# create-cell infers the cloud provider from the template name (v5-<provider>-*)
# and lets --cloud-provider override it before shelling out to omni. We stub omni
# on PATH so we can assert on the command line it receives.

setup() {
	STUB_DIR="$(mktemp -d)"
	cat > "$STUB_DIR/omni" <<-'EOF'
		#!/usr/bin/env sh
		# record that omni actually ran, so any dry-run tests can assert it didn't
		touch "$(dirname "$0")/ran"
		printf 'omni %s\n' "$*"
	EOF
	chmod +x "$STUB_DIR/omni"
	PATH="$STUB_DIR:$PATH"
}

teardown() {
	rm -rf "$STUB_DIR"
}

@test "infers --cloud-provider gcp from a gcp template" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cloud-provider gcp"* ]]
}

@test "infers --cloud-provider aws from an aws template" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-aws-small
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cloud-provider aws"* ]]
}

@test "explicit --cloud-provider overrides the inferred provider" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small --cloud-provider aws
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cloud-provider aws"* ]]
	[[ "$output" != *"--cloud-provider gcp"* ]]
}

@test "-p is an alias for --cloud-provider" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-aws-small -p gcp
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cloud-provider gcp"* ]]
}

@test "--cloud-provider=VALUE form is accepted" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-aws-small --cloud-provider=gcp
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cloud-provider gcp"* ]]
}

@test "omits --cloud-provider for a template with no provider hint" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v6-micro-walker-nightly
	[ "$status" -eq 0 ]
	[[ "$output" != *"--cloud-provider"* ]]
}

@test "passes cell id, benchgo, namespace, and template through to omni" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small
	[ "$status" -eq 0 ]
	[[ "$output" == *"omni scaffold environment create"* ]]
	[[ "$output" == *"--cell-id mycell"* ]]
	[[ "$output" == *"--benchgo-enabled"* ]]
	[[ "$output" == *"--namespace mycell-marathon"* ]]
	[[ "$output" == *"--yaml v5-gcp-small"* ]]
}

@test "actually invokes omni" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small
	[ "$status" -eq 0 ]
	[ -f "$STUB_DIR/ran" ]
}

@test "--dry-run prints the resolved command but does not run omni" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *"omni scaffold environment create"* ]]
	[[ "$output" == *"--cloud-provider gcp"* ]]
	[ ! -f "$STUB_DIR/ran" ]
}

@test "-n is an alias for --dry-run" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small -n
	[ "$status" -eq 0 ]
	[ ! -f "$STUB_DIR/ran" ]
}
