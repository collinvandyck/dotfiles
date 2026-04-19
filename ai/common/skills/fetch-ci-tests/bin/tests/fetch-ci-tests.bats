#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../fetch-ci-tests"
}

@test "no args prints usage" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" =~ Usage: ]]
}

@test "unknown arg prints usage" {
  run "$SCRIPT" --bogus
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown arg" ]]
}

@test "dry-run with --pr resolves run ID" {
  run "$SCRIPT" --dry-run --pr 6685
  [ "$status" -eq 0 ]
  [[ "$output" =~ "would fetch" ]]
}

@test "dry-run with --pr URL extracts number and repo" {
  run "$SCRIPT" --dry-run --pr https://github.com/temporalio/saas-temporal/pull/6685
  [ "$status" -eq 0 ]
  [[ "$output" =~ "would fetch" ]]
}

@test "dry-run with --run skips PR resolution" {
  run "$SCRIPT" --dry-run --run 23824300838
  [ "$status" -eq 0 ]
  [[ "$output" =~ "would fetch all artifacts for run 23824300838" ]]
}
