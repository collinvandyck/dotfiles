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

qq() {
	# disableAllHooks: skip the superpowers SessionStart hook, which otherwise
	# injects "you MUST invoke a skill" context and forces an extra skill/tool
	# round-trip even for trivial prompts. CLAUDE.md/MCP/skills still load.
	cl --settings '{"disableAllHooks":true}' --model haiku --effort low -p "$(
		<<-EOF
			The user has a request. When using fenced code blocks also include language identifiers.

			User: "$*"
		EOF
	)" | glow
}
