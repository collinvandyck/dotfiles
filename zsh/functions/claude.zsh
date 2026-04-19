cldsp() {
	claude "$@" --allow-dangerously-skip-permissions --dangerously-skip-permissions
}

clcdsp() {
	claude --continue "$@" --allow-dangerously-skip-permissions --dangerously-skip-permissions
}

clrdsp() {
	claude --resume "$@" --allow-dangerously-skip-permissions --dangerously-skip-permissions
}

clpr() {
	[[ $# == 0 ]] && {
		echo "usage: $0 [url] [...]"
		return 1
	}
	local title="lpr $1"
	if [[ $1 =~ '([^/]+)/pull/([0-9]+)' ]]; then
		title="lpr ${match[1]}/${match[2]}"
	fi
	claude --name "$title" --effort high -- "/local-pr-review $*"
}
