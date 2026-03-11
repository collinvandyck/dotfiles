#!/usr/bin/env bats

@test "joins lines within a paragraph" {
	run "$BATS_TEST_DIRNAME/paragraphs" <<-'EOF'
		one
		two
		three
	EOF
	[ "$status" -eq 0 ]
	[ "$output" = "one two three" ]
}

@test "preserves paragraph breaks" {
	run "$BATS_TEST_DIRNAME/paragraphs" <<-'EOF'
		one
		two
		three

		four
	EOF
	[ "$status" -eq 0 ]
	expected="$(printf 'one two three\n\nfour')"
	[ "$output" = "$expected" ]
}

@test "preserves multiple blank lines between paragraphs" {
	run "$BATS_TEST_DIRNAME/paragraphs" <<-'EOF'
		alpha
		bravo


		charlie
	EOF
	[ "$status" -eq 0 ]
	expected="$(printf 'alpha bravo\n\n\ncharlie')"
	[ "$output" = "$expected" ]
}

@test "single line passes through unchanged" {
	run "$BATS_TEST_DIRNAME/paragraphs" <<< "hello world"
	[ "$status" -eq 0 ]
	[ "$output" = "hello world" ]
}

@test "empty input produces empty output" {
	run "$BATS_TEST_DIRNAME/paragraphs" < /dev/null
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "handles three paragraphs" {
	run "$BATS_TEST_DIRNAME/paragraphs" <<-'EOF'
		a
		b

		c
		d

		e
	EOF
	[ "$status" -eq 0 ]
	expected="$(printf 'a b\n\nc d\n\ne')"
	[ "$output" = "$expected" ]
}

@test "reads from a file argument" {
	tmp="$(mktemp)"
	printf 'line one\nline two\n\nline three\n' > "$tmp"
	run "$BATS_TEST_DIRNAME/paragraphs" "$tmp"
	[ "$status" -eq 0 ]
	expected="$(printf 'line one line two\n\nline three')"
	[ "$output" = "$expected" ]
	rm -f "$tmp"
}

@test "trailing newline does not create extra output" {
	run "$BATS_TEST_DIRNAME/paragraphs" <<-'EOF'
		foo
		bar
	EOF
	[ "$status" -eq 0 ]
	[ "$output" = "foo bar" ]
}
