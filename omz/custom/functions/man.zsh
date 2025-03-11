man() {
	rename() { tmux rename-window "$@" &>/dev/null || true }
	num-panes() { tmux display-message -p '#{window_panes}' || "0" }
    man-help() { $1 --help | nvim '+Man!' }
	local title=$(tmux display-message -p '#W' || true)
	trap "rename '$title'" EXIT
	[[ "$(num-panes)" == "1" ]] && rename "man $*"
    case $1 in
        we) man-help watchexec ;;
        watchexec|bat) man-help $1 ;;
        *) command man "$@";;
    esac
}
