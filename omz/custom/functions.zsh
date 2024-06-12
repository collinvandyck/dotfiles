# remove functions set by oh my zsh
unset -f d
unset -f git_main_branch

function tmp() {
	cd $(mktemp -d)
}

# runs the dfk command, and if the first argument is s3, then it creates a new
# temporary directory, renames the tmux window to the arguments to the s3 command and
# execs a new shell in that temp dir if successful so that the user can remain
# in that shell and inspect the output.
#
# after the command is finished, successfully or otherwise, the tmux window name
# will be restored.
dfk() {
	case "${1}" in 
		s3)
			shift
			local title=$(tmux display-message -p '#W' || true)
			local args=$(printf "%q " "$@")
			tmux rename-window "s3: $args" 2>/dev/null
			zsh -c "$(cat <<-EOF
				cd "$(mktemp -d)"
				if ! command dfk s3 $args; then
					exit 1
				fi
				exec zsh
			EOF
			)"
			tmux rename-window "$title" 2>/dev/null
			;;
		*)
			command dfk "$@"
			;;
	esac
}
