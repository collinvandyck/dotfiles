#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# git-tidy offers local branches that look finished for deletion one at a time, archiving each under refs/archive/.
# With -n it only lists them, one tab-separated row per candidate on stdout: verdict, branch, age, unpushed commits.
# The harness builds a real repo with a bare origin so git behaves for real, and stubs gh and gum on PATH so PR state
# comes from $GH_PR_LIST and every menu answers $GUM_CHOICE.

setup() {
	export TMP="$(mktemp -d)"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@e
	export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@e

	git init -q --bare "$TMP/origin.git"
	git init -q -b main "$TMP/myrepo"
	git -C "$TMP/myrepo" commit -q --allow-empty -m init
	git -C "$TMP/myrepo" remote add origin "$TMP/origin.git"
	git -C "$TMP/myrepo" push -q -u origin main

	mkdir -p "$TMP/bin"
	stub_gh
	stub_gum
	export GUM_LOG="$TMP/gum.log"
	PATH="$TMP/bin:$PATH"

	cd "$TMP/myrepo"
}

teardown() {
	rm -rf "$TMP"
}

# A merged PR whose head holds the branch tip makes the branch a candidate.
@test "lists a branch whose merged PR head holds its tip" {
	branch_with_commit collin/done
	oid=$(git rev-parse collin/done)
	GH_PR_LIST=$'7\tMERGED\tcollin/done\t'"$oid" run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'merged #7\tcollin/done\t0d\t0' ]
}

# Commits made after the PR merged would be lost, so the branch isn't offered as merged.
@test "keeps a branch with commits beyond its merged PR head" {
	branch_with_commit collin/more
	oid=$(git rev-parse collin/more)
	git switch -q collin/more
	git commit -q --allow-empty -m "after the merge"
	git switch -q main
	GH_PR_LIST=$'7\tMERGED\tcollin/more\t'"$oid" run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# An open PR keeps a branch even when it would otherwise look stale.
@test "keeps a stale branch with an open PR" {
	branch_with_commit collin/slow 60
	oid=$(git rev-parse collin/slow)
	GH_PR_LIST=$'8\tOPEN\tcollin/slow\t'"$oid" run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# A branch with nothing beyond origin/main is already in it.
@test "lists a branch that is an ancestor of origin/main" {
	git branch collin/empty origin/main
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'in origin/main\tcollin/empty\t0d\t0' ]
}

# A squash merge leaves main with the branch's diff but none of its commits.
@test "lists a branch whose changes were squashed into origin/main" {
	git switch -q -c collin/sq
	echo one >a && git add a && git commit -q -m "add a"
	echo two >b && git add b && git commit -q -m "add b"
	git switch -q main
	echo one >a && echo two >b
	git add a b && git commit -q -m "squash collin/sq"
	git push -q origin main
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'squashed into origin/main\tcollin/sq\t0d\t2' ]
}

# Deleting the remote branch leaves the local one tracking nothing.
@test "lists a branch whose upstream is gone and counts what only it holds" {
	branch_with_commit alfred/fix
	git push -q -u origin alfred/fix
	git push -q origin --delete alfred/fix
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'upstream gone\talfred/fix\t0d\t1' ]
}

# Backup and heads/* names are leftovers no matter how recent.
@test "lists branches whose names mark them as junk" {
	branch_with_commit backup-pre-fixup
	branch_with_commit heads/v1.2
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'junk\tbackup-pre-fixup\t0d\t1\njunk\theads/v1.2\t0d\t1' ]
}

# A branch named like a tag makes the bare name ambiguous, so it's junk even when recent.
@test "lists a branch that shadows a tag as junk" {
	branch_with_commit v1.2.3
	git tag v1.2.3 origin/main
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'junk\tv1.2.3\t0d\t1' ]
}

# A branch with no commit in 28 days is stale.
@test "lists a branch with no recent commit as stale" {
	branch_with_commit collin/old 60
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ "$output" = $'stale\tcollin/old\t60d\t1' ]
}

# A recent branch with its own commits is work in progress.
@test "keeps a recent branch with unpushed work" {
	branch_with_commit collin/wip
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# Worktree branches belong to wt sweep.
@test "skips a branch checked out in a worktree" {
	git worktree add -q "$TMP/myrepo-wt" -b collin/wt origin/main
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# branch.<name>.keep opts a branch out.
@test "skips a branch marked keep" {
	git branch collin/pinned origin/main
	git config branch.collin/pinned.keep true
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# The local main is always an ancestor of origin/main, but it's not a candidate.
@test "skips the local base branch" {
	git switch -q -c collin/here
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" -n
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# Choosing delete archives the tip under refs/archive/ before the branch goes, and prints nothing to stdout.
@test "delete archives the branch and removes it" {
	branch_with_commit collin/old 60
	sha=$(git rev-parse collin/old)
	GUM_CHOICE=delete run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
	! git show-ref --verify --quiet refs/heads/collin/old
	[ "$(git rev-parse refs/archive/collin/old)" = "$sha" ]
}

# Skip leaves the branch and archives nothing.
@test "skip leaves the branch alone" {
	branch_with_commit collin/old 60
	GUM_CHOICE=skip run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	git show-ref --verify --quiet refs/heads/collin/old
	[ -z "$(git for-each-ref refs/archive)" ]
}

# Quit stops at the first prompt rather than moving on to the next candidate.
@test "quit stops before the remaining candidates" {
	branch_with_commit collin/old1 60
	branch_with_commit collin/old2 60
	GUM_CHOICE=quit run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	[ "$(grep -c '^choose' "$GUM_LOG")" -eq 1 ]
}

# Commits only the branch holds are shown before the prompt, so you see what deleting would put at risk.
@test "shows unpushed commits before asking" {
	branch_with_commit collin/old 60
	git switch -q collin/old
	GIT_COMMITTER_DATE="$(($(date +%s) - 60 * 86400)) +0000" git commit -q --allow-empty -m "precious work"
	git switch -q main
	GUM_CHOICE=skip run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	grep -qF "precious work" "$GUM_LOG"
}

# The PR number in a merged verdict links to the PR.
@test "links the PR number to the PR url" {
	branch_with_commit collin/done
	oid=$(git rev-parse collin/done)
	url=https://github.com/o/r/pull/7
	GH_PR_LIST=$'7\tMERGED\tcollin/done\t'"$oid"$'\t'"$url" GUM_CHOICE=skip GIT_COMMON_HYPERLINKS=1 \
		run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	grep -qF $'merged \e]8;;'"$url"$'\e\\#7\e]8;;\e\\' "$GUM_LOG"
}

# An unpushed commit GitHub still has links to its page there.
@test "links an unpushed commit that GitHub knows" {
	branch_with_commit collin/old 60
	sha=$(git rev-parse collin/old)
	short=$(git rev-parse --short collin/old)
	GH_REPO_URL=https://github.com/o/r GH_KNOWN_COMMITS="$sha" GUM_CHOICE=skip GIT_COMMON_HYPERLINKS=1 \
		run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	grep -qF $'\e]8;;https://github.com/o/r/commit/'"$sha"$'\e\\'"$short"$'\e]8;;\e\\ collin/old' "$GUM_LOG"
}

# A commit GitHub never saw would link to a 404, so it stays plain.
@test "leaves an unpushed commit GitHub doesn't know unlinked" {
	branch_with_commit collin/old 60
	short=$(git rev-parse --short collin/old)
	GH_REPO_URL=https://github.com/o/r GUM_CHOICE=skip GIT_COMMON_HYPERLINKS=1 \
		run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	grep -qF "    $short collin/old" "$GUM_LOG"
}

# Archiving a second branch of the same name keeps the first one's tip in the archive ref's reflog.
@test "archiving a name twice keeps the earlier tip in the reflog" {
	branch_with_commit collin/again 60
	first=$(git rev-parse collin/again)
	GUM_CHOICE=delete run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	branch_with_commit collin/again 61
	GUM_CHOICE=delete run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	[ "$status" -eq 0 ]
	git reflog show --format=%H refs/archive/collin/again | grep -qx "$first"
}

# restore puts the branch back at its archived tip and drops the archive ref.
@test "restore recreates an archived branch" {
	branch_with_commit collin/old 60
	sha=$(git rev-parse collin/old)
	GUM_CHOICE=delete run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" restore collin/old
	[ "$status" -eq 0 ]
	[ "$(git rev-parse refs/heads/collin/old)" = "$sha" ]
	! git show-ref --verify --quiet refs/archive/collin/old
}

# With no branch, restore picks from the archive.
@test "restore with no branch picks one" {
	branch_with_commit collin/old 60
	GUM_CHOICE=delete run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	GUM_CHOICE=collin/old run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" restore
	[ "$status" -eq 0 ]
	git show-ref --verify --quiet refs/heads/collin/old
}

# restore won't clobber a branch that has since been recreated.
@test "restore refuses when the branch exists again" {
	branch_with_commit collin/old 60
	GUM_CHOICE=delete run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy"
	git branch collin/old origin/main
	run --separate-stderr "$BATS_TEST_DIRNAME/git-tidy" restore collin/old
	[ "$status" -ne 0 ]
	[ "$(git rev-parse collin/old)" = "$(git rev-parse origin/main)" ]
	git show-ref --verify --quiet refs/archive/collin/old
}

# --- helpers ---

# branch_with_commit NAME [DAYS_AGO] — branch NAME off origin/main with one commit of its own, dated DAYS_AGO
# days back (default now). Leaves main checked out.
branch_with_commit() {
	local when
	when="$(($(date +%s) - ${2:-0} * 86400)) +0000"
	git switch -q -c "$1" origin/main
	GIT_COMMITTER_DATE="$when" GIT_AUTHOR_DATE="$when" git commit -q --allow-empty -m "$1"
	git switch -q main
}

# gum stub: logs its args to $GUM_LOG; choose/filter answer $GUM_CHOICE (or pass the menu through), and everything
# else (style, …) is swallowed.
stub_gum() {
	cat >"$TMP/bin/gum" <<-'EOF'
		#!/usr/bin/env sh
		[ -n "${GUM_LOG:-}" ] && printf '%s\n' "$*" >>"$GUM_LOG"
		case "$1" in
		choose | filter)
			menu=$(cat)
			if [ -n "${GUM_CHOICE:-}" ]; then printf '%s\n' "$GUM_CHOICE"; else printf '%s\n' "$menu"; fi
			;;
		*) : ;;
		esac
	EOF
	chmod +x "$TMP/bin/gum"
}

# gh stub: prints $GH_PR_LIST for `pr list` and $GH_REPO_URL for `repo view`; `api` for a commit succeeds only when
# its sha is in the space-separated $GH_KNOWN_COMMITS.
stub_gh() {
	cat >"$TMP/bin/gh" <<-'EOF'
		#!/usr/bin/env sh
		if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
			printf '%s\n' "${GH_PR_LIST:-}"
		elif [ "$1" = "repo" ] && [ "$2" = "view" ]; then
			printf '%s\n' "${GH_REPO_URL:-}"
		elif [ "$1" = "api" ]; then
			case " ${GH_KNOWN_COMMITS:-} " in
			*" ${2##*/} "*) exit 0 ;;
			*) exit 1 ;;
			esac
		fi
	EOF
	chmod +x "$TMP/bin/gh"
}
