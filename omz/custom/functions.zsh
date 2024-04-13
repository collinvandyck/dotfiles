# remove functions set by oh my zsh
unset -f d

function tmp() {
	cd $(mktemp -d)
}

