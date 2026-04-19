#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../safe-grep"
  TMPFILE=$(mktemp)
  cat > "$TMPFILE" <<'EOF'
{"command":"grep -o 'foo|bar'","tool":"Bash"}
{"command":"echo hello","tool":"Bash"}
{"command":"rg 'baz|qux'","tool":"Grep"}
EOF
}

teardown() {
  rm -f "$TMPFILE"
}

@test "missing args prints usage" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" =~ Usage: ]]
}

@test "missing file arg prints usage" {
  run "$SCRIPT" "somepattern"
  [ "$status" -eq 1 ]
  [[ "$output" =~ Usage: ]]
}

@test "file not found" {
  run "$SCRIPT" "pattern" "/nonexistent/file"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "File not found" ]]
}

@test "invalid regex" {
  run "$SCRIPT" "[invalid" "$TMPFILE"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Invalid regex" ]]
}

@test "dry-run prints command without executing" {
  run "$SCRIPT" --dry-run "foo|bar" "$TMPFILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "would run" ]]
}

@test "matches pattern with pipe" {
  run "$SCRIPT" "foo\|bar" "$TMPFILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "foo|bar" ]]
}

@test "matches pattern with quotes" {
  run "$SCRIPT" '"command"' "$TMPFILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ '"command"' ]]
}

@test "no matches exits 1" {
  run "$SCRIPT" "zzzznothere" "$TMPFILE"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}
