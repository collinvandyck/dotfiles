#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# goland-inherit copies a root worktree's .idea config into the current worktree.
# The harness builds a real repo with a linked worktree so root/target resolution
# behaves for real, and stubs the interactive deps (gum, pgrep) on PATH.

setup() {
	export TMP="$(mktemp -d)"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@e
	export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@e

	git init -q -b main "$TMP/myrepo"
	git -C "$TMP/myrepo" commit -q --allow-empty -m init

	mkdir -p "$TMP/bin"
	stub_gum
	stub_pgrep ""   # GoLand not running by default
	export GUM_LOG="$TMP/gum.log"
	PATH="$TMP/bin:$PATH"

	REPO="$TMP/myrepo"
	# a linked worktree is the normal place to run goland-inherit from
	git -C "$REPO" worktree add -q "$TMP/myrepo-wt" -b wt
	WT="$TMP/myrepo-wt"

	BIN="$BATS_TEST_DIRNAME/goland-inherit"
}

teardown() { rm -rf "$TMP"; }

@test "errors when not in a git repository" {
	cd "$TMP"
	run "$BIN"
	[ "$status" -ne 0 ]
	[[ "$output" == *"not in a git repository"* ]]
}

@test "errors when run from the main worktree with no ROOT (no parent to inherit)" {
	mkdir -p "$REPO/.idea"
	cd "$REPO"
	run "$BIN"
	[ "$status" -ne 0 ]
	[[ "$output" == *"root worktree"* ]]
}

@test "no-ops when the root has no .idea" {
	cd "$WT"
	run "$BIN"
	[ "$status" -eq 0 ]
	[[ "$output" == *"nothing to inherit"* ]]
	[ ! -e "$WT/.idea" ]
}

# --- helpers ---

# gum stub: confirm honors $GUM_CONFIRM (default 1 = No); logs args to $GUM_LOG.
stub_gum() {
	cat > "$TMP/bin/gum" <<-'EOF'
		#!/usr/bin/env sh
		[ -n "${GUM_LOG:-}" ] && echo "$*" >> "$GUM_LOG"
		[ "$1" = "confirm" ] && exit "${GUM_CONFIRM:-1}"
		exit 0
	EOF
	chmod +x "$TMP/bin/gum"
}

# pgrep stub: exits 0 (found) when the hit file is non-empty, else 1.
stub_pgrep() {
	printf '%s' "${1:-}" > "$TMP/pgrep.hit"
	cat > "$TMP/bin/pgrep" <<-EOF
		#!/usr/bin/env sh
		[ -s "$TMP/pgrep.hit" ] && exit 0 || exit 1
	EOF
	chmod +x "$TMP/bin/pgrep"
}
