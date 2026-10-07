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
	stub_gh
	export MISE_LOG="$TMP/mise.log"
	export GUM_LOG="$TMP/gum.log"
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

@test "a multi-word bare invocation is slugified into a single worktree" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" test this and that
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-test-this-and-that" ]
	[[ "$output" == *"/myrepo-test-this-and-that" ]]
	[ ! -d "$TMP/myrepo-test" ]
}

@test "a bare slug containing a slash is rejected and creates nothing" {
	before="$(git worktree list | wc -l)"
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" collin/foo
	[ "$status" -ne 0 ]
	[ -z "$output" ]
	grep -q "bad slug" "$GUM_LOG"
	[ ! -e "$TMP/myrepo-collin" ]
	[ "$before" -eq "$(git worktree list | wc -l)" ]
}

@test "add rejects a slug containing a slash before touching the repo" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" add collin/foo
	[ "$status" -ne 0 ]
	[ -z "$output" ]
	grep -q "bad slug" "$GUM_LOG"
	[ ! -e "$TMP/myrepo-collin" ]
	! git show-ref --verify --quiet refs/heads/collin/collin/foo
}

@test "add rejects slugs that would escape or hide the worktree dir" {
	for bad in ../escape .hidden 'a b;rm' '$(whoami)' 'a~b'; do
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" add "$bad"
		[ "$status" -ne 0 ]
		grep -q "bad slug" "$GUM_LOG"
	done
	# only the main worktree remains
	[ "$(git worktree list | wc -l)" -eq 1 ]
}

@test "add accepts dots, dashes and underscores inside a slug" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" add v1.2_fix-x
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-v1.2_fix-x" ]
	[ "$(git -C "$TMP/myrepo-v1.2_fix-x" rev-parse --abbrev-ref HEAD)" = "collin/v1.2_fix-x" ]
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

@test "add excludes the symlinked .claude via the worktree's info/exclude" {
	mkdir "$REPO/.claude"
	run "$BATS_TEST_DIRNAME/worktrees" add withclaude
	[ "$status" -eq 0 ]
	excl="$(git -C "$TMP/myrepo-withclaude" rev-parse --path-format=absolute --git-path info/exclude)"
	grep -qxF '.claude' "$excl"
}

@test "pr with no args lists PRs (including author) and checks out into our own tracked branch" {
	line=$'7\tcollin\tfix the thing\tcollin/fix'
	GH_PR_LIST="$line" GUM_CHOICE="$line" run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" pr
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-pr-7" ]
	grep -q author "$TMP/gh.log"
	grep -q -- "pr checkout 7 --branch collin/pr-7" "$TMP/gh.log"
	[ "$(git -C "$TMP/myrepo-pr-7" config --get push.default)" = "current" ]
	[ "$(git -C "$TMP/myrepo-pr-7" config --get branch.collin/pr-7.pushRemote)" = "origin" ]
	[[ "$output" == *"/myrepo-pr-7" ]]
}

@test "pr with a url for a different repo errors before doing anything" {
	git remote set-url origin https://github.com/temporalio/temporal.git
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" pr https://github.com/someone/fork/pull/9
	[ "$status" -ne 0 ]
	[ ! -d "$TMP/myrepo-pr-9" ]
	[ ! -f "$TMP/gh.log" ] || ! grep -q "pr checkout" "$TMP/gh.log"
}

@test "pr with a url matching the repo remote checks it out" {
	git remote set-url origin https://github.com/temporalio/temporal.git
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" pr https://github.com/temporalio/temporal/pull/9
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-pr-9" ]
	grep -q -- "--branch collin/pr-9" "$TMP/gh.log"
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

@test "the switch picker orders worktrees by last-active, most recent first" {
	# names chosen so alphabetical/creation order (aaa, zzz) disagrees with
	# recency: aaa is older, zzz is newer, so last-active must put zzz first.
	git worktree add -q "$TMP/myrepo-aaa" -b collin/aaa
	GIT_COMMITTER_DATE="2020-01-01T00:00:00 +0000" git -C "$TMP/myrepo-aaa" commit -q --allow-empty -m aaa
	git worktree add -q "$TMP/myrepo-zzz" -b collin/zzz
	GIT_COMMITTER_DATE="2030-01-01T00:00:00 +0000" git -C "$TMP/myrepo-zzz" commit -q --allow-empty -m zzz

	GUM_MENU_LOG="$TMP/menu" run "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	[ "$(sed -n 1p "$TMP/menu")" = "zzz" ]
	[ "$(sed -n 2p "$TMP/menu")" = "aaa" ]
}

@test "the switch picker omits [root] when already in the main repo root" {
	git worktree add -q "$TMP/myrepo-a" -b collin/a
	# setup leaves us in the main root
	GUM_MENU_LOG="$TMP/menu" run "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	! grep -qxF '[root]' "$TMP/menu"
}

@test "switch with no worktrees never opens the picker" {
	# main root, no linked worktrees -> nothing to pick; the picker must not open
	# (gum filter on empty input falls back to listing files)
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
	[ ! -f "$TMP/gum.log" ] || ! grep -q filter "$TMP/gum.log"
}

@test "selecting [root] in the switch picker returns the main repo root" {
	git worktree add -q "$TMP/myrepo-a" -b collin/a
	cd "$TMP/myrepo-a"
	GUM_CHOICE="[root]" run --separate-stderr "$BATS_TEST_DIRNAME/worktrees"
	[ "$status" -eq 0 ]
	[[ "$output" == *"/myrepo" ]]
	[[ "$output" != *"/myrepo-a" ]]
}

@test "rm removes a worktree you're not in and stays put (empty stdout)" {
	git worktree add -q "$TMP/myrepo-doomed" -b collin/doomed
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm doomed
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-doomed" ]
	[ -z "$output" ]
}

@test "rm from inside the target worktree removes it and returns you to root" {
	git worktree add -q "$TMP/myrepo-here" -b collin/here
	cd "$TMP/myrepo-here"
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm here
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-here" ]
	[[ "$output" == *"/myrepo" ]]
	[[ "$output" != *"/myrepo-here" ]]
}

@test "rm of a dirty worktree force-removes it once confirmed" {
	git worktree add -q "$TMP/myrepo-dirty" -b collin/dirty
	touch "$TMP/myrepo-dirty/untracked"
	GUM_CONFIRM=0 run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm dirty
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-dirty" ]
}

@test "rm of a dirty worktree leaves it in place when the force prompt is declined" {
	git worktree add -q "$TMP/myrepo-dirty" -b collin/dirty
	touch "$TMP/myrepo-dirty/untracked"
	# GUM_CONFIRM defaults to 1 (No) — the worktree must survive.
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm dirty
	[ "$status" -ne 0 ]
	[ -d "$TMP/myrepo-dirty" ]
}

@test "rm with no arg multi-selects and removes every picked worktree, staying put" {
	git worktree add -q "$TMP/myrepo-one" -b collin/one
	git worktree add -q "$TMP/myrepo-two" -b collin/two
	git worktree add -q "$TMP/myrepo-keep" -b collin/keep
	GUM_CHOICE=$'one\ntwo' run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-one" ]
	[ ! -d "$TMP/myrepo-two" ]
	[ -d "$TMP/myrepo-keep" ]
	[ -z "$output" ]
}

@test "rm multi-select opens the picker with multi-selection enabled" {
	git worktree add -q "$TMP/myrepo-one" -b collin/one
	GUM_CHOICE=one run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm
	[ "$status" -eq 0 ]
	grep -q -- '--no-limit' "$GUM_LOG"
}

@test "rm multi-select that includes the cwd removes all and returns you to root" {
	git worktree add -q "$TMP/myrepo-here" -b collin/here
	git worktree add -q "$TMP/myrepo-other" -b collin/other
	cd "$TMP/myrepo-here"
	GUM_CHOICE=$'here\nother' run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-here" ]
	[ ! -d "$TMP/myrepo-other" ]
	[[ "$output" == *"/myrepo" ]]
	[[ "$output" != *"/myrepo-"* ]]
}

@test "rm multi-select skips a dirty pick whose force-confirm is declined but removes the rest" {
	git worktree add -q "$TMP/myrepo-clean" -b collin/clean
	git worktree add -q "$TMP/myrepo-dirty" -b collin/dirty
	touch "$TMP/myrepo-dirty/untracked"
	# GUM_CONFIRM defaults to 1 (No) — the dirty force-confirm is declined.
	GUM_CHOICE=$'clean\ndirty' run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-clean" ]
	[ -d "$TMP/myrepo-dirty" ]
}

@test "rm multi-select from inside a declined dirty pick leaves you put" {
	git worktree add -q "$TMP/myrepo-clean" -b collin/clean
	git worktree add -q "$TMP/myrepo-dirty" -b collin/dirty
	touch "$TMP/myrepo-dirty/untracked"
	cd "$TMP/myrepo-dirty"
	# GUM_CONFIRM defaults to 1 (No) — the dirty force-confirm is declined, so the
	# cwd survives and we should stay put rather than being handed back to root.
	GUM_CHOICE=$'dirty\nclean' run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" rm
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-dirty" ]
	[ ! -d "$TMP/myrepo-clean" ]
	[ -z "$output" ]
}

@test "add inherits the root's .idea into the new worktree" {
	mkdir -p "$REPO/.idea"
	printf '<project version="4"/>' > "$REPO/.idea/workspace.xml"
	printf '<module/>' > "$REPO/.idea/myrepo.iml"
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" add withidea
	[ "$status" -eq 0 ]
	[ -f "$TMP/myrepo-withidea/.idea/workspace.xml" ]
	[ -f "$TMP/myrepo-withidea/.idea/myrepo.iml" ]
	# stdout is the dir for wt to cd into — the hook's chatter must stay on stderr
	[[ "$output" == *"/myrepo-withidea" ]]
	[[ "$output" != *inherited* ]]
}

@test "add succeeds and writes no .idea when the root has none" {
	run "$BATS_TEST_DIRNAME/worktrees" add noidea
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-noidea" ]
	[ ! -e "$TMP/myrepo-noidea/.idea" ]
}

@test "sweep removes a worktree whose merged PR head is its HEAD and stays put" {
	wt_with_commit done
	oid="$(git -C "$TMP/myrepo-done" rev-parse HEAD)"
	GH_PR_LIST=$'7\tMERGED\tcollin/done\t'"$oid" GUM_CHOICE=remove \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-done" ]
	[ -z "$output" ]
}

@test "sweep links the PR number to the PR url" {
	wt_with_commit done
	oid="$(git -C "$TMP/myrepo-done" rev-parse HEAD)"
	url=https://github.com/o/r/pull/7
	GH_PR_LIST=$'7\tMERGED\tcollin/done\t'"$oid"$'\t'"$url" GUM_CHOICE=skip GIT_COMMON_HYPERLINKS=1 \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	grep -qF $'\e]8;;'"$url"$'\e\\#7\e]8;;\e\\' "$GUM_LOG"
}

@test "sweep prints the PR number without escapes when stderr isn't a terminal" {
	wt_with_commit done
	oid="$(git -C "$TMP/myrepo-done" rev-parse HEAD)"
	GH_PR_LIST=$'7\tMERGED\tcollin/done\t'"$oid"$'\thttps://github.com/o/r/pull/7' GUM_CHOICE=skip \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	grep -qF "merged #7 (" "$GUM_LOG"
}

@test "sweep leaves a candidate in place when it's skipped" {
	wt_with_commit done
	oid="$(git -C "$TMP/myrepo-done" rev-parse HEAD)"
	GH_PR_LIST=$'7\tMERGED\tcollin/done\t'"$oid" GUM_CHOICE=skip \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-done" ]
}

@test "sweep never offers a recent worktree with an open PR" {
	wt_with_commit wip
	oid="$(git -C "$TMP/myrepo-wip" rev-parse HEAD)"
	GH_PR_LIST=$'8\tOPEN\tcollin/wip\t'"$oid" GUM_CHOICE=remove \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-wip" ]
}

@test "sweep keeps a worktree with commits beyond its merged PR head" {
	wt_with_commit more
	oid="$(git -C "$TMP/myrepo-more" rev-parse HEAD)"
	git -C "$TMP/myrepo-more" commit -q --allow-empty -m "after the merge"
	GH_PR_LIST=$'7\tMERGED\tcollin/more\t'"$oid" GUM_CHOICE=remove \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-more" ]
}

@test "sweep offers a worktree with nothing beyond origin/main" {
	git worktree add -q "$TMP/myrepo-empty" -b collin/empty origin/main
	GUM_CHOICE=remove run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-empty" ]
}

@test "sweep offers a detached worktree whose commits are all on a remote branch" {
	git switch -q -c other
	git commit -q --allow-empty -m other
	git push -q origin other
	git switch -q main
	git worktree add -q --detach "$TMP/myrepo-det" other
	GUM_CHOICE=remove run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-det" ]
}

@test "sweep looks up a pr-N worktree by number and offers it once that PR merged" {
	wt_with_commit pr-9
	oid="$(git -C "$TMP/myrepo-pr-9" rev-parse HEAD)"
	GH_PR_VIEW=$'MERGED\t'"$oid" GUM_CHOICE=remove \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-pr-9" ]
	grep -q "pr view 9" "$TMP/gh.log"
}

@test "sweep offers a stale worktree but not a recent one with the same unpushed work" {
	git worktree add -q "$TMP/myrepo-old" -b collin/old
	GIT_COMMITTER_DATE="2020-01-01T00:00:00 +0000" git -C "$TMP/myrepo-old" commit -q --allow-empty -m old
	wt_with_commit fresh
	GUM_CHOICE=remove run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-old" ]
	[ -d "$TMP/myrepo-fresh" ]
}

@test "sweep prompts for one worktree at a time and quit stops before the next" {
	git worktree add -q "$TMP/myrepo-a" -b collin/a origin/main
	git worktree add -q "$TMP/myrepo-b" -b collin/b origin/main
	GUM_CHOICE=quit run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ -d "$TMP/myrepo-a" ]
	[ -d "$TMP/myrepo-b" ]
	[ "$(grep -c '^choose' "$GUM_LOG")" -eq 1 ]
}

@test "sweep that removes the cwd returns you to root" {
	git worktree add -q "$TMP/myrepo-here" -b collin/here origin/main
	cd "$TMP/myrepo-here"
	GUM_CHOICE=remove run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-here" ]
	[[ "$output" == *"/myrepo" ]]
}

@test "sweep offers to delete the checked-out branch even when it doesn't match the slug" {
	git worktree add -q "$TMP/myrepo-flip" -b collin/renamed
	git -C "$TMP/myrepo-flip" commit -q --allow-empty -m work
	oid="$(git -C "$TMP/myrepo-flip" rev-parse HEAD)"
	GH_PR_LIST=$'7\tMERGED\tcollin/renamed\t'"$oid" GUM_CHOICE=remove GUM_CONFIRM=0 \
		run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/myrepo-flip" ]
	! git show-ref --verify --quiet refs/heads/collin/renamed
}

@test "sweep --all sweeps every repo under the dir from outside any repo" {
	git init -q --bare "$TMP/origin2.git"
	git init -q -b main "$TMP/second"
	git -C "$TMP/second" commit -q --allow-empty -m init
	git -C "$TMP/second" remote add origin "$TMP/origin2.git"
	git -C "$TMP/second" push -q -u origin main
	git -C "$TMP/second" worktree add -q "$TMP/second-x" -b collin/x origin/main
	git worktree add -q "$TMP/myrepo-y" -b collin/y origin/main
	cd "$TMP"
	GUM_CHOICE=remove run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep --all "$TMP"
	[ "$status" -eq 0 ]
	[ ! -d "$TMP/second-x" ]
	[ ! -d "$TMP/myrepo-y" ]
	[ -z "$output" ]
}

@test "sweep skips the PR lookup for a repo with no sibling worktrees" {
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	[ ! -f "$TMP/gh.log" ]
}

@test "sweep prunes worktree entries whose dir is already gone" {
	git worktree add -q "$TMP/myrepo-gone" -b collin/gone
	rm -rf "$TMP/myrepo-gone"
	run --separate-stderr "$BATS_TEST_DIRNAME/worktrees" sweep
	[ "$status" -eq 0 ]
	! git worktree list | grep -q myrepo-gone
}

# --- helpers ---

# wt_with_commit SLUG — a sibling worktree on collin/SLUG with one commit of its own.
wt_with_commit() {
	git worktree add -q "$TMP/myrepo-$1" -b "collin/$1"
	git -C "$TMP/myrepo-$1" commit -q --allow-empty -m "$1"
}

# gum stub: confirm honors $GUM_CONFIRM (default 1 = No); choose/filter record the
# menu to $GUM_MENU_LOG (if set) then echo $GUM_CHOICE or pass the menu through;
# everything else (style/format/…) is swallowed.
stub_gum() {
	cat > "$TMP/bin/gum" <<-'EOF'
		#!/usr/bin/env sh
		[ -n "${GUM_LOG:-}" ] && printf '%s\n' "$*" >> "$GUM_LOG"
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
		printf '%s\n' "\$*" >> "$TMP/$1.log"
	EOF
	chmod +x "$TMP/bin/$1"
}

# gh stub: logs args like stub_logger, prints $GH_PR_LIST for `pr list` so the
# picker has rows to choose from, and $GH_PR_VIEW for `pr view`.
stub_gh() {
	cat > "$TMP/bin/gh" <<-EOF
		#!/usr/bin/env sh
		printf '%s\n' "\$*" >> "$TMP/gh.log"
		if [ "\$1" = "pr" ] && [ "\$2" = "list" ]; then
			printf '%s\n' "\${GH_PR_LIST:-}"
		elif [ "\$1" = "pr" ] && [ "\$2" = "view" ]; then
			printf '%s\n' "\${GH_PR_VIEW:-}"
		fi
	EOF
	chmod +x "$TMP/bin/gh"
}
