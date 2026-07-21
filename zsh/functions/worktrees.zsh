# launches the worktrees script and cds into the resultiing dir
wt() {
	setopt local_options err_return no_unset pipe_fail

	local dir="$(command worktrees "$@")" || return 1
	[[ -z "$dir" ]] && return
	cd -- "$dir"
}
