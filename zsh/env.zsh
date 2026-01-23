# todo: this adds about 10-15ms of startup time

#export GOROOT=/usr/local/go
#export GOPATH=~/code/go
unset GOROOT
unset GOPATH

export XDG_CONFIG_HOME=~/.config
export K9S_CONFIG_DIR=~/.config/k9s

export BAT_STYLE="plain"
export DOCKER_CLI_HINTS=false
export DOCKER_SCAN_SUGGEST=false
export EDITOR=nvim
export FLOX_DISABLE_METRICS=true
export GO111MODULE=on
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export HOSTNAME=$(hostname)
export HWATCH="--color --no-help-banner --border --with-scrollbar"
export KUBE_EDITOR=nvim
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# this is to prevent apt/systemd from asking to restart services.
# with this setting the services will automatically be restarted.
export NEEDRESTART_MODE=a

if [[ "$(hostname)" != "ryzen-ubuntu" ]]; then
    export LC_ALL=en_US.UTF-8
fi
export LESS="-XFR"
export LESS='-R'

# use nvim as the manpage pager.
# gO while in nvim takes you to the outline.
export MANPAGER='nvim +Man!'
#export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export PAGER='less -RX' # -X turns off the screen clearing function
export PANTS_LINT=true
export PYENV_ROOT="$HOME/.pyenv"
export RIPGREP_CONFIG_PATH=~/.ripgrep.conf
#export WORDCHARS='*?_-[]~&;!#$%^(){}<>|'
export WORDCHARS=-

export PATH=~/.local/bin:$PATH
export PATH=~/.fzf/bin:$PATH
export PATH=~/.cargo/bin:$PATH
export PATH=~/code/temporal-utils:$PATH
export PATH=~/go/bin:$PATH
export PATH=/snap/bin:$PATH
export PATH=/usr/local/go/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=/opt/homebrew/share/google-cloud-sdk/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=~/.dotfiles/bin:$PATH
