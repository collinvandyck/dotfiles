#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# worktrees is the brains behind the `wt` shell function. It creates sibling
# worktrees by convention (<repo>-<slug>, branch collin/<slug>, off origin/main)
# and prints the dir to cd into on stdout — empty stdout means "stay put".
#
# The harness builds a real repo with a bare origin so git behaves for real, and
# stubs the interactive/external deps (gum, mise, gh) on PATH. Tests assert on the
# contract, not the internals — this thing will get reshaped.

setup() {
	export TMP="$(mktemp -d)"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@e
	export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@e

	# bare origin + a working clone named 'myrepo' with an origin/main to branch from
	git init -q --bare "$TMP/origin.git"
	git init -q -b main "$TMP/myrepo"
	git -C "$TMP/myrepo" commit -q --allow-empty -m init
	git -C "$TMP/myrepo" remote add origin "$TMP/origin.git"
	git -C "$TMP/myrepo" push -q -u origin main

	mkdir -p "$TMP/bin"
	stub_gum
	stub_logger mise
	stub_logger gh
	export MISE_LOG="$TMP/mise.log"
	PATH="$TMP/bin:$PATH"

	REPO="$TMP/myrepo"
	cd "$REPO"
}

teardown() {
	rm -rf "$TMP"
}

@test "add creates a sibling worktree and prints its path to stdout" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" add feature-x
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-feature-x" ]
	[[ "$output" == *"/myrepo-feature-x" ]]
}

@test "add creates the branch collin/<slug>" {
	run "$BATS_TEST_DIRNAME/worktrees" add feature-x
	[ "$status" -eq 0 ]
	[ "$(git -C "$TMP/myrepo-feature-x" rev-parse --abbrev-ref HEAD)" = "collin/feature-x" ]
}

@test "add fetches origin and bases the branch on the latest origin/main" {
	# advance origin/main from a second clone so REPO's tracking ref is stale;
	# a worktree at the advanced commit proves the fetch happened.
	git clone -q "$TMP/origin.git" "$TMP/other"
	git -C "$TMP/other" commit -q --allow-empty -m advance
	git -C "$TMP/other" push -q origin main

	run "$BATS_TEST_DIRNAME/worktrees" add fresh
	[ "$status" -eq 0 ]
	[ "$(git -C "$TMP/myrepo-fresh" rev-parse HEAD)" = "$(git -C "$TMP/other" rev-parse HEAD)" ]
}

@test "derives the repo name from the main worktree even when run inside a worktree" {
	git worktree add -q "$TMP/myrepo-existing" -b collin/existing
	cd "$TMP/myrepo-existing"

	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" add nested
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-nested" ]
	[ ! -d "$TMP/myrepo-existing-nested" ]
}

@test "a bare slug that uniquely matches an existing worktree prints its path and creates nothing" {
	git worktree add -q "$TMP/myrepo-vis-admin" -b collin/vis-admin
	before="$(git worktree list | wc -l)"

	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" vis
	[ "$status" -eq 0 ]
	[[ "$output" == *"/myrepo-vis-admin" ]]
	[ "$before" -eq "$(git worktree list | wc -l)" ]
}

@test "ls lists worktrees but writes nothing to stdout (no cd)" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" ls
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "-h prints usage and the command list to stderr without a cd" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" -h
	[ "$status" -eq 0 ]
	[ -z "$output" ]
	[[ "$stderr" == *usage* ]]
	[[ "$stderr" == *add* ]]
	[[ "$stderr" == *rm* ]]
	[[ "$stderr" == *pr* ]]
}

@test "add symlinks .claude into the new worktree when the main repo has one" {
	mkdir "$REPO/.claude"
	run "$BATS_TEST_DIRNAME/worktrees" add withclaude
	[ "$status" -eq 0 ]
	[ -L "$TMP/myrepo-withclaude/.claude" ]
}

@test "add runs mise install when the new worktree contains a mise.toml" {
	printf '' > "$REPO/mise.toml"
	git add mise.toml
	git commit -q -m "add mise.toml"
	git push -q origin main

	run "$BATS_TEST_DIRNAME/worktrees" add withmise
	[ "$status" -eq 0 ]
	grep -q install "$MISE_LOG"
}

@test "the switch picker lists [root] first when run from a linked worktree" {
	git worktree add -q "$TMP/myrepo-a" -b collin/a
	cd "$TMP/myrepo-a"
	GUM_MENU_LOG="$TMP/menu" run "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	[ "$(head -n1 "$TMP/menu")" = "[root]" ]
}

@test "the switch picker omits [root] when already in the main repo root" {
	git worktree add -q "$TMP/myrepo-a" -b collin/a
	# setup leaves us in the main root
	GUM_MENU_LOG="$TMP/menu" run "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	! grep -qxF '[root]' "$TMP/menu"
}

@test "selecting [root] in the switch picker returns the main repo root" {
	git worktree add -q "$TMP/myrepo-a" -b collin/a
	cd "$TMP/myrepo-a"
	GUM_CHOICE="[root]" run --separate-stderr "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	[[ "$output" == *"/myrepo" ]]
	[[ "$output" != *"/myrepo-a" ]]
}

@test "rm removes the worktree" {
	git worktree add -q "$TMP/myrepo-doomed" -b collin/doomed
	run "$BATS_TEST_DIRNAME/worktrees" rm doomed
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-doomed" ]
}

# --- helpers ---

# gum stub: confirm honors $GUM_CONFIRM (default 1 = No); choose/filter record the
# menu to $GUM_MENU_LOG (if set) then echo $GUM_CHOICE or pass the menu through;
# everything else (style/format/…) is swallowed.
stub_gum() {
	cat > "$TMP/bin/gum" <<-'EOF'
		#!/usr/bin/env sh
		sub=$1; shift
		case "$sub" in
			confirm) exit "${GUM_CONFIRM:-1}" ;;
			choose|filter)
				menu=$(cat)
				[ -n "${GUM_MENU_LOG:-}" ] && printf '%s\n' "$menu" > "$GUM_MENU_LOG"
				if [ -n "${GUM_CHOICE:-}" ]; then printf '%s\n' "$GUM_CHOICE"; else printf '%s\n' "$menu"; fi
				;;
			*) : ;;
		esac
	EOF
	chmod +x "$TMP/bin/gum"
}

# stub_logger NAME — a stub that appends its args to $TMP/NAME.log so tests can
# assert it ran and with what.
stub_logger() {
	cat > "$TMP/bin/$1" <<-EOF
		#!/usr/bin/env sh
		echo "\$*" >> "$TMP/$1.log"
	EOF
	chmod +x "$TMP/bin/$1"
}
