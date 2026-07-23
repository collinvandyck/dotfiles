# launches the worktrees script and cds into the resultiing dir
wt() {
	setopt local_options err_return no_unset pipe_fail

	local dir="$(command worktrees "$@")" || return 1
	[[ -z "$dir" ]] && return
	cd -- "$dir"
}

# wtsh [commit]  — open a throwaway detached worktree at <commit> (default HEAD),
# drop into a shell there, and remove the worktree when that shell exits.
wtsh() {
	local commit=${1:-HEAD} wt
	wt=$(mktemp -d "${TMPDIR:-/tmp}/wt-$(git rev-parse --short "$commit" 2>/dev/null || echo x)-XXXX") || return 1
	git worktree add --detach "$wt" "$commit" || {
		rmdir "$wt" 2>/dev/null
		return 1
	}
	(
		trap 'echo "removing wt $wt"; git worktree remove --force "$wt" 2>/dev/null' EXIT INT TERM HUP
		cd "$wt" || exit 1
		echo "→ worktree at $commit ($wt); exit / ctrl-d to clean up"
		[[ -f mise.toml ]] && mise --quiet trust && mise --quiet install
		"${SHELL:-/bin/zsh}" # NOT exec — subshell must outlive it to run the trap
	)
}
