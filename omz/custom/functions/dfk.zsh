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
			local in_shell=$(echo $title | grep -E '^s3');
			tmux rename-window "s3: $args" 2>/dev/null
			if [ -f .dfks3 ]; then
				# if we are in the shell then don't bother creating a new one
				command dfk s3 $args
				return $?
			fi
			zsh -c "$(cat <<-EOF
				cd "$(mktemp -d)"
				touch .dfks3
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

