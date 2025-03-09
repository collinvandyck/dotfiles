man() {
	rename() { tmux rename-window "$@" &>/dev/null || true }
	num-panes() { tmux display-message -p '#{window_panes}' || "0" }
	local title=$(tmux display-message -p '#W' || true)
	trap "rename '$title'" EXIT
	[[ "$(num-panes)" == "1" ]] && rename "man $*"
    command man "$@"
}
