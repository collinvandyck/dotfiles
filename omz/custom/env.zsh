#export GOROOT=/usr/local/go
#export GOPATH=~/code/go
unset GOROOT
unset GOPATH

export BAT_STYLE="plain"
export DOCKER_CLI_HINTS=false
export DOCKER_SCAN_SUGGEST=false
export EDITOR=nvim
export FLOX_DISABLE_METRICS=true
export GO111MODULE=on
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export HOSTNAME=$(hostname)
export HTOPRC=~/.dotfiles/htop/htop.rc
export HWATCH="--color --no-help-banner --border --with-scrollbar"
export KUBE_EDITOR=nvim
export LESS="-XFR"
export LESS='-R'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PAGER='less -RX' # -X turns off the screen clearing function
export PANTS_LINT=true
export PYENV_ROOT="$HOME/.pyenv"
export RIPGREP_CONFIG_PATH=~/.ripgrep.conf
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

paths=()
for p in $(echo $PATH | tr ':' '\n'); do
	paths+=($p)
done

# addPath adds the path if it exists and is not already in PATH
addPath() {
	local add=$1
	paths=("${(@)paths:#$add}")
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
	/usr/local/sqlite3/bin
	$PYENV_ROOT
)

for p in ${addPaths[@]}; do
	addPath $(echo $p)
done

