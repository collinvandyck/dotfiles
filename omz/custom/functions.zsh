# remove functions set by oh my zsh
unset -f d
unset -f git_main_branch

function tmp() {
	cd $(mktemp -d)
}

