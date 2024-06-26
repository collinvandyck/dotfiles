# Launches nvim, renaming the tmux window to the thing being edited. This only
# happens when there is exactly one pane in the current window.
nvim() {
	rename() {
		tmux rename-window "$@" &>/dev/null || true
	}
	num-panes() {
		tmux display-message -p '#{window_panes}' || "0"
	}
	local title=$(tmux display-message -p '#W' || true)
	trap "rename '$title'" EXIT
	[ "$(num-panes)" = "1" ] && {
		if [ $# -eq 0 ]; then 
			title="v:$(basename $(pwd))"
		else
			title="v:$@"
		fi
		rename "$title"
	}
	command nvim
}
