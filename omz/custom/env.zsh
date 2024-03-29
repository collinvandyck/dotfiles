#export GOROOT=/usr/local/go
#export GOPATH=~/code/go
unset GOROOT
unset GOPATH

export DOCKER_SCAN_SUGGEST=false
export EDITOR=nvim
export GO111MODULE=on
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_GOOGLE_ANALYTICS=1
export KUBE_EDITOR=nvim
export LESS="-XFR"
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
export PANTS_LINT=true
export HOSTNAME=$(hostname)
export BAT_STYLE="plain"
export LESS='-R'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PAGER='less -RX' # -X turns off the screen clearing function
export RIPGREP_CONFIG_PATH=~/.ripgrep.conf
export HTOPRC=~/.dotfiles/htop/htop.rc

paths=()
for p in $(echo $PATH | tr ':' '\n'); do
	paths+=($p)
done

# addPath adds the path if it exists and is not already in PATH
addPath() {
	local add=$1
	for p in ${paths[@]}; do
		if [ "$p" = "$add" ]; then
			return 0
		fi
	done
	if ! [ -d $add ]; then
		return 0
	fi
	export PATH="$add:$PATH"
}

addPaths=(
	/opt/homebrew/bin
	/opt/homebrew/sbin
	~/Library/Python/3.9/bin
	~/go/bin
	~/bin
	~/.fzf/bin
	~/.local/bin
	~/.cargo/bin
	~/.tfenv/bin
	~/.powerline/scripts
	/usr/local/go/bin
	/usr/local/bin
	~/.dotfiles/bin
	/usr/local/flutter/bin
	/usr/local/sqlite3/bin
)

for p in ${addPaths[@]}; do
	addPath $(echo $p)
done

