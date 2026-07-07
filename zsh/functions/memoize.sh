# sets the output of the rest of the command to the o variable.
memoize() {
	o=$("$@" | tee /dev/tty)
}

with_memoize() {
	if ! [[ -v o ]]; then
		echo >&2 "output not set"
		return 1
	fi
	<<<"$o" "$@"
}

alias o=memoize
alias oo=with_memoize
