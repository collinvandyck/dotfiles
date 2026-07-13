#!/usr/bin/env bash
# Publish the pages repo: (optionally) commit, then rebase, push, wait for the
# GitHub Pages CI build, then print and open the resulting GitHub Pages URL(s).
#
# Usage: publish.sh [-m "commit message"] [path ...]
#   -m MSG    Commit before pushing. Stages the given paths, or `git add -A`
#             if none are given. Omit -m if you've already committed.
#   path ...  Repo-relative targets to open (a directory opens its index).
#             With no paths, opens the .html files changed in HEAD.
#
# Run from inside a checkout of temporalio/pages.
set -euo pipefail

REPO_SLUG="temporalio/pages"
WORKFLOW="pages.yml"

msg=""
while getopts "m:" opt; do
	case "$opt" in
	m) msg="$OPTARG" ;;
	*)
		echo "usage: publish.sh [-m \"commit message\"] [path ...]" >&2
		exit 2
		;;
	esac
done
shift $((OPTIND - 1))

cd "$(git rev-parse --show-toplevel)"

# 1. Commit if a message was given.
if [ -n "$msg" ]; then
	if [ "$#" -gt 0 ]; then
		git add -- "$@"
	else
		git add -A
	fi
	echo "==> git commit"
	git commit -m "$msg"
fi

# 2. Rebase on remote, then push what's committed.
echo "==> git pull --rebase"
git pull --rebase
echo "==> git push"
git push

SHA="$(git rev-parse HEAD)"

# 3. Decide what to open: explicit args, else the .html files changed in HEAD.
paths=()
if [ "$#" -gt 0 ]; then
	paths=("$@")
else
	while IFS= read -r f; do
		[ -n "$f" ] && paths+=("$f")
	done < <(git show --pretty= --name-only HEAD | grep -Ei '\.html?$' || true)
fi

# 4. Find the workflow run for this commit, then watch it to completion.
echo "==> waiting for the Pages build of ${SHA:0:7} to register ..."
run_id=""
for _ in $(seq 1 30); do
	run_id="$(gh run list --repo "$REPO_SLUG" --workflow "$WORKFLOW" -L 20 \
		--json databaseId,headSha \
		--jq ".[] | select(.headSha==\"$SHA\") | .databaseId" | head -n1)"
	[ -n "$run_id" ] && break
	sleep 2
done
if [ -z "$run_id" ]; then
	echo "could not find a Pages workflow run for $SHA" >&2
	exit 1
fi
echo "==> watching run $run_id"
gh run watch "$run_id" --repo "$REPO_SLUG" --exit-status

# 5. Resolve the (non-guessable, private) Pages base URL from the API.
base="$(gh api "repos/$REPO_SLUG/pages" --jq .html_url)"
base="${base%/}"

# 6. Print and open the URL(s).
if [ "${#paths[@]}" -eq 0 ]; then
	echo "published. site: $base/"
	open "$base/"
	exit 0
fi

for p in "${paths[@]}"; do
	p="${p#./}"
	p="${p%/}"
	if [ -d "$p" ]; then
		url="$base/$p/"
	else
		url="$base/$p"
	fi
	echo "$url"
	open "$url"
done
