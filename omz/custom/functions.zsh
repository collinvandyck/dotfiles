# remove functions set by oh my zsh
unset -f d

# cd's into an ngrok directory
function cdn() {
	cd ~/ngrok/$(cd ~/ngrok && find -type d -not -path '*/.*' | fzf --preview 'ls -lh {}')
}

function mantd() {
	name=$(tmux display-message -p '#W')
	tmux rename-window "man $@"
	command man $@
	tmux rename-window "$name"
}

function awddown() {
	sudo bash -c 'while :; do ifconfig awdl0 down; date; sleep 5; done'
}

function loc() {
	echo $(rg --files -g '*.go' | rg -v '_test.go' | xargs cat | wc -l)
}

function loc-test() {
	echo $(rg --files -g '*.go' | rg '_test.go' | xargs cat | wc -l)
}

function tmp() {
	cd $(mktemp -d)
}

function notifywait() {
    while inotifywait \
        --exclude .swp \
        --exclude .idea \
        --exclude .git \
        -e close_write \
        -qq \
        -r .
    do
    $@;
    done
}

function vimrc() {
    vi ~/.vimrc
}

function cpu() {
    watch -n.1 "grep \"^[c]pu MHz\" /proc/cpuinfo"
}

function track() {
    git branch -u origin/$(git rev-parse --abbrev-ref HEAD)
}

function cip() {
    ci ${@} && put
    fg 2>/dev/null || true
}

# cd into a directory and change tmux pane name
function tcd() {
    cd ${1}
    td
}

function _fzf_complete_htop_post() {
    echo "-p $(awk '{print $2}')"
}

function _fzf_complete_htop() {
  _fzf_complete --multi --reverse --prompt="process> " -- "$@" < <(
    ps -ef
  )
}

function _fzf_complete_wow() {
  _fzf_complete --multi --reverse --prompt="doge> " -- "$@" < <(
    echo very
    echo wow
    echo such
    echo doge
  )
}

function newPassword() {
    len=${1:-"16"}
    cat /dev/urandom| head -c 64 | base64 -w 0 | sed -e 's/[\/\+\=]//g' | head -c ${len}
}

function td()
{
	if [[ $# > 0 ]]; then
		tmux rename-window "$@" 2>/dev/null
	else
		tmux rename-window "$(basename $(pwd))" 2>/dev/null
	fi
}

function fixssh() {
  for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT; do
    if (tmux show-environment | grep "^${key}" > /dev/null); then
      value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
      export ${key}="${value}"
    fi
  done
}

function lines() {
    setopt promptsubst
    PS1=$'${(r:$COLUMNS::\u2500:)}'$PS1
}

function lines_underscores() {
    setopt promptsubst
    PS1=$'${(r:$COLUMNS::_:)}'$PS1
}

preview() {
	qlmanage -p "$@" > /dev/null
}
