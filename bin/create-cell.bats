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
	# keep the real set-cell from rewriting ~/.envrc
	printf '#!/usr/bin/env sh\n' > "$STUB_DIR/set-cell"
	chmod +x "$STUB_DIR/set-cell"
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

@test "default cell name is s-collin-YYMMDD-<cloud> for the inferred provider" {
	run "$BATS_TEST_DIRNAME/create-cell" --template v5-gcp-small -n
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cell-id s-collin-$(date +%y%m%d)-gcp "* ]]
	[[ "$output" == *"--namespace s-collin-$(date +%y%m%d)-gcp-marathon"* ]]
}

@test "default cell name uses an explicit --cloud-provider" {
	run "$BATS_TEST_DIRNAME/create-cell" --template v5-gcp-small -p aws -n
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cell-id s-collin-$(date +%y%m%d)-aws "* ]]
}

@test "default cell name shortens azure to az" {
	run "$BATS_TEST_DIRNAME/create-cell" --template v6-micro-walker-nightly -p azure -n
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cell-id s-collin-$(date +%y%m%d)-az "* ]]
}

@test "default cell name falls back to aws when no provider is known" {
	run "$BATS_TEST_DIRNAME/create-cell" --template v6-micro-walker-nightly -n
	[ "$status" -eq 0 ]
	[[ "$output" == *"--cell-id s-collin-$(date +%y%m%d)-aws "* ]]
}

@test "-n is an alias for --dry-run" {
	run "$BATS_TEST_DIRNAME/create-cell" --cell mycell --template v5-gcp-small -n
	[ "$status" -eq 0 ]
	[ ! -f "$STUB_DIR/ran" ]
}
