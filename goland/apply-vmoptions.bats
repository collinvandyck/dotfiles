#!/usr/bin/env bats

setup() {
	TEST_DIR="$(mktemp -d)"
	mkdir -p "$TEST_DIR/GoLand2025.3"

	# simulate a typical Toolbox-managed vmoptions file
	cat > "$TEST_DIR/GoLand2025.3/goland.vmoptions" <<-'EOF'
		-Dide.managed.by.toolbox=/Applications/JetBrains Toolbox.app/Contents/MacOS/jetbrains-toolbox
		-Dtoolbox.notification.token=abc-123
		-Dtoolbox.notification.portFile=/Users/test/Library/Caches/JetBrains/Toolbox/ports/test.port
		-Xmx2048m
	EOF
}

teardown() {
	rm -rf "$TEST_DIR"
}

result() {
	cat "$TEST_DIR/GoLand2025.3/goland.vmoptions"
}

@test "replaces -Xmx with value from vmoptions.conf" {
	run "$BATS_TEST_DIRNAME/apply-vmoptions" "$TEST_DIR"
	[ "$status" -eq 0 ]

	run result
	[[ "$output" == *"-Xmx1536m"* ]]
	[[ "$output" != *"-Xmx2048m"* ]]
}

@test "preserves Toolbox-managed lines" {
	run "$BATS_TEST_DIRNAME/apply-vmoptions" "$TEST_DIR"
	[ "$status" -eq 0 ]

	run result
	[[ "$output" == *"-Dide.managed.by.toolbox="* ]]
	[[ "$output" == *"-Dtoolbox.notification.token=abc-123"* ]]
	[[ "$output" == *"-Dtoolbox.notification.portFile="* ]]
}

@test "is idempotent" {
	"$BATS_TEST_DIRNAME/apply-vmoptions" "$TEST_DIR"
	"$BATS_TEST_DIRNAME/apply-vmoptions" "$TEST_DIR"

	run result
	count=$(echo "$output" | grep -c "\-Xmx1536m")
	[ "$count" -eq 1 ]
}

@test "handles multiple GoLand versions" {
	mkdir -p "$TEST_DIR/GoLand2025.2"
	cat > "$TEST_DIR/GoLand2025.2/goland.vmoptions" <<-'EOF'
		-Xmx2048m
		-Dide.managed.by.toolbox=/path/to/toolbox
	EOF

	run "$BATS_TEST_DIRNAME/apply-vmoptions" "$TEST_DIR"
	[ "$status" -eq 0 ]

	# both versions updated
	[[ "$(cat "$TEST_DIR/GoLand2025.2/goland.vmoptions")" == *"-Xmx1536m"* ]]
	[[ "$(cat "$TEST_DIR/GoLand2025.3/goland.vmoptions")" == *"-Xmx1536m"* ]]
}

@test "skips directories without goland.vmoptions" {
	mkdir -p "$TEST_DIR/GoLand2024.1"
	# no vmoptions file created

	run "$BATS_TEST_DIRNAME/apply-vmoptions" "$TEST_DIR"
	[ "$status" -eq 0 ]
	[ ! -f "$TEST_DIR/GoLand2024.1/goland.vmoptions" ]
}

@test "no GoLand directories is a no-op" {
	empty="$(mktemp -d)"
	run "$BATS_TEST_DIRNAME/apply-vmoptions" "$empty"
	[ "$status" -eq 0 ]
	rm -rf "$empty"
}
