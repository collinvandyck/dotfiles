#!/usr/bin/env bats

# ct-safety-guard reads a PreToolUse payload on stdin and prints a deny decision, or nothing to allow the call.

guard() {
	jq -n --arg cmd "$1" '{tool_input: {command: $cmd}}' | "$BATS_TEST_DIRNAME/ct-safety-guard.sh"
}

@test "allows skip flags on an s-cds-collin cell" {
	run guard "ct ocld test dc cell patch -c s-cds-collin-261116 --skip-approval --skip-confirmation"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "allows skip flags on an s-collin- cell" {
	run guard "ct ocld test dc cell patch -c s-collin-261118-gcp --skip-approval --skip-confirmation"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "denies skip flags on a cell that only shares the s-collin prefix" {
	run guard "ct ocld test dc cell patch -c s-collins-261118 --skip-approval"
	[[ "$output" == *'"deny"'* ]]
}

@test "denies skip flags when any named cell isn't mine" {
	run guard "ct ocld test dc cell patch -c s-collin-261118-aws -c s-other-1 --skip-approval"
	[[ "$output" == *'"deny"'* ]]
}

@test "denies skip flags with no cell" {
	run guard "ct ocld test dc cell patch --skip-approval"
	[[ "$output" == *'"deny"'* ]]
}

@test "denies a glob cell even with my prefix" {
	run guard "ct ocld test dc cell patch -c 's-collin-*' --skip-approval"
	[[ "$output" == *'"deny"'* ]]
}

@test "allows SkipApprovals in a workflow input for an s-collin- cell" {
	run guard 'temporal workflow start --input '"'"'{"Cell": {"ID": "s-collin-261118-aws"}, "SkipApprovals": true}'"'"
	[ -z "$output" ]
}

@test "denies SkipApprovals in a workflow input for another cell" {
	run guard 'temporal workflow start --input '"'"'{"Cell": {"ID": "s-other-1"}, "SkipApprovals": true}'"'"
	[[ "$output" == *'"deny"'* ]]
}

@test "denies prod outright" {
	run guard "ct ocld prod cell db get -c s-collin-261118-aws"
	[[ "$output" == *'"deny"'* ]]
}
