clpr() {
	[[ $# == 0 ]] && {
		echo "usage: $0 [url] [...]"
		return 1
	}
	local title="lpr $1"
	if [[ $1 =~ '([^/]+)/pull/([0-9]+)' ]]; then
		title="lpr ${match[1]}/${match[2]}"
	fi
	(
		cd ~/code/temporal
		claude --name "$title" --effort high -- "/local-pr-review $*"
	)
}
