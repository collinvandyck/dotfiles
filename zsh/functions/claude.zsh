# this file is zsh. SC2296 fires on zsh ${(flag)param} expansions, which
# shellcheck (bash-only) can't parse -- disable it file-wide.
# shellcheck disable=SC2296

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
	cl --settings '{"disableAllHooks":true}' --model haiku -p "$(
		<<-EOF
			The user has a request. When using fenced code blocks also include language identifiers.
			The output will be flowed through a markdown formatter which does not support mermaid syntax, so avoid using mermaid diagrams.

			User: "$*"
		EOF
	)" | glow
}

# claude resume session helper. lists the most recent sessions across all
# projects in an fzf picker, then cd's into the session's launch dir and
# resumes it. optional arg caps how many sessions to list (default 20).
#
# launch dir = the recorded cwd whose '/'->'-' encoding matches the project
# folder. a session may cd anywhere mid-run, so first/last cwd is unreliable;
# only the launch dir is a valid `claude --resume` target. titles use the last
# value so renames win. NB: keep comments OUT of the sel=$(...) below -- zsh
# reparses command substitutions at runtime and breaks on a stray ' or ` in a
# comment when the interactive_comments option is off.
cr() {
	launch-finder() {
		local num_sessions=${1:-50}
		local sel
		sel=$(
			find ~/.claude/projects -name '*.jsonl' -mindepth 2 -maxdepth 2 -print0 \
			| xargs -0 ls -t 2>/dev/null \
			| head -$num_sessions \
			| while read -r f; do
				line=$(jq -rs '
					(input_filename | split("/") | .[-2]) as $folder |
					(map(.sessionId  // empty)              | last) as $id |
					(map(.customTitle // empty)             | last) as $custom |
					(map(select(.type=="ai-title").aiTitle) | last) as $ai |
					((map(.cwd // empty) | map(select(gsub("/";"-") == $folder)) | first)
					 // (map(.cwd // empty) | first)) as $cwd |
					"\($cwd)\t\($id)\t\($custom // $ai // $id)"
				' "$f")
				IFS=$'\t' read -r cwd id session <<< "$line"
				printf '%s\t%s\t%s\t%s\n' "$f" "$cwd" "$id" "${(D)cwd}:$session"
			done \
			| fzf --ansi \
						--delimiter='\t' \
						--with-nth=4 \
						--no-hscroll \
						--height=100% --layout=reverse --border --prompt='cr › ' \
						--preview 'cr-preview-glow {1}' \
						--preview-window='right,55%,wrap'
		) || return 1
		local f cwd id rest
		IFS=$'\t' read -r f cwd id rest <<< "$sel"
		(cd "$cwd" && claude --resume "$id")
	}
	while launch-finder; do :; done
}
