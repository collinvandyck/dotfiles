function gcob() {
	local branches=$(git branch --all --sort=committerdate | grep -v remotes)
	local choice=$(echo "$branches" | fzf-tmux -p --no-sort --tac | tr -d '[:space:]' | tr -d '^\* ')
	[ "$choice" ] || return ok
	git checkout "$choice"
}
