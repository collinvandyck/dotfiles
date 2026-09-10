which-release() {
	local out
	out=$(
		cd ~/code/saas-temporal 2>/dev/null &&
			git tag --contains "$1" --sort=creatordate |
			rg '^v' |
				head -1 \
					2>/dev/null
	)
	[[ -n "$out" ]] && echo "$out"
}

admintools-pod() {
	cell=${1:-$CELL}
	[[ -z "$cell" ]] && {
		echo "no cell provided"
		return 1
	}
	ctt kc --context $cell get po -n temporal -l app.kubernetes.io/component=admintools -o custom-columns=:metadata.name --no-headers
}
