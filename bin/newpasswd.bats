#!/usr/bin/env bats

# newpasswd builds a password of a given length with guaranteed minimums of
# symbols and digits. A bare/absent flag means "at least one"; an explicit
# count means "exactly N". These tests lean on the deterministic guarantees
# (forced counts and fixed length), so nothing here is probabilistic.

SYMSET='!@#$%^&*()'
DIGSET='0-9'

# count CHARSET STR -> number of chars in STR that belong to CHARSET.
count() {
	printf '%s' "$2" | tr -cd "$1" | wc -c | tr -d ' '
}

@test "defaults to length 32" {
	run "$BATS_TEST_DIRNAME/newpasswd"
	[ "$status" -eq 0 ]
	[ "${#output}" -eq 32 ]
}

@test "respects --length" {
	run "$BATS_TEST_DIRNAME/newpasswd" --length 16
	[ "$status" -eq 0 ]
	[ "${#output}" -eq 16 ]
}

@test "respects -l short flag" {
	run "$BATS_TEST_DIRNAME/newpasswd" -l 8
	[ "$status" -eq 0 ]
	[ "${#output}" -eq 8 ]
}

@test "default includes at least one symbol and one digit" {
	run "$BATS_TEST_DIRNAME/newpasswd"
	[ "$status" -eq 0 ]
	[ "$(count "$SYMSET" "$output")" -ge 1 ]
	[ "$(count "$DIGSET" "$output")" -ge 1 ]
}

@test "--symbols 0 produces no symbols" {
	run "$BATS_TEST_DIRNAME/newpasswd" --symbols 0
	[ "$status" -eq 0 ]
	[ "$(count "$SYMSET" "$output")" -eq 0 ]
}

@test "--digits 0 produces no digits" {
	run "$BATS_TEST_DIRNAME/newpasswd" --digits 0
	[ "$status" -eq 0 ]
	[ "$(count "$DIGSET" "$output")" -eq 0 ]
}

@test "--symbols 0 --digits 0 yields letters only" {
	run "$BATS_TEST_DIRNAME/newpasswd" -s 0 -d 0
	[ "$status" -eq 0 ]
	[ "${#output}" -eq 32 ]
	[ "$(count "$SYMSET" "$output")" -eq 0 ]
	[ "$(count "$DIGSET" "$output")" -eq 0 ]
}

@test "--symbols N produces exactly N symbols" {
	run "$BATS_TEST_DIRNAME/newpasswd" --symbols 3
	[ "$status" -eq 0 ]
	[ "$(count "$SYMSET" "$output")" -eq 3 ]
}

@test "--digits N produces exactly N digits" {
	run "$BATS_TEST_DIRNAME/newpasswd" --digits 4
	[ "$status" -eq 0 ]
	[ "$(count "$DIGSET" "$output")" -eq 4 ]
}

@test "explicit symbols and digits compose to exact counts" {
	run "$BATS_TEST_DIRNAME/newpasswd" -s 2 -d 3 -l 16
	[ "$status" -eq 0 ]
	[ "${#output}" -eq 16 ]
	[ "$(count "$SYMSET" "$output")" -eq 2 ]
	[ "$(count "$DIGSET" "$output")" -eq 3 ]
}

@test "bare --symbols still guarantees at least one" {
	run "$BATS_TEST_DIRNAME/newpasswd" -s -d 0
	[ "$status" -eq 0 ]
	[ "$(count "$SYMSET" "$output")" -ge 1 ]
	[ "$(count "$DIGSET" "$output")" -eq 0 ]
}

@test "clamps a symbol count larger than the length" {
	run "$BATS_TEST_DIRNAME/newpasswd" -s 100 -l 8
	[ "$status" -eq 0 ]
	[ "${#output}" -eq 8 ]
	[ "$(count "$SYMSET" "$output")" -eq 8 ]
}

@test "rejects unknown flags" {
	run "$BATS_TEST_DIRNAME/newpasswd" --nope
	[ "$status" -eq 1 ]
	[[ "$output" == *usage* ]]
}
