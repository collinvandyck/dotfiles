# rust aliases
alias co='cargo'
alias we='watchexec'
alias wer='we -e rs'
alias wert='we -e rs cargo t'

# git aliases
alias gst='git status'
alias gcav='git add -A && git commit -v'
alias gb='GIT_PAGER= git branch --sort=committerdate'
alias gf='git fetch'
alias gl='git pull'
alias glr='git pull --rebase'
alias gll='git ll'
alias gllc='git ll --glob="refs/*/collin/*" --glob="refs/*/main"'
alias glla='git lla'
alias glog='git log'
alias log='glog'
alias stash='git add -A && git stash'
alias pop='git stash pop'
alias gitk='gitk --all > /dev/null 2>&1 &'
alias gr='git reset'
alias grh='git reset --hard'
alias grhom='grh origin/main'
alias grhlb='grh @{-1}'
alias grom='gr origin/master'
alias grlb='gr @{-1}'
alias rev='git rev-parse HEAD'
alias gg='git grep'
alias put='git put'
alias gla='git last'
alias shove='git shove'
alias show='git show'
alias lg='lazygit'
alias amend='git commit --amend'

# remove things that the git plugin defines
unalias gup

# zsh aliases
alias reload='source ~/.zshrc'
alias ll='ls -lF'
alias lla='ll -a'
alias llh='ll -h'
alias llr='ls -lrth'

# k8s things
alias mk='minikube'
alias kc='kubectl'
alias kcl='kubectl logs'
alias kclt='kcl -f --tail=10'

# docker stuff
alias dc='docker-compose'
alias dcdown='dc down -v -t 0'
alias dcup='dc up -d'
alias dcupb='dc up -d --build'
alias dcupp='dc down -v -t 0; dc up -d --build'
alias dcuppl='dcupp && dclogs'
alias dclogs='dc logs -f'
alias dclogst='dc logs -f --tail 15'
alias dps="docker ps --no-trunc --format '{{.Names}}\t{{.Image}}\t{{.Command}}'"

# clipboard
if [ ! -f "/usr/bin/pbcopy" ]; then
    alias pbcopy='xsel --clipboard --input'
fi
if [ ! -f "/usr/bin/pbpaste" ]; then
    alias pbpaste='xsel --clipboard --output'
fi

# other
alias nowrap='cut -c -$COLUMNS'
alias d='cd ~/.dotfiles'
alias c='cd ~/code'

# ls --color makes me sad because it's hard to read.
unalias ls

# show the top 10 active files on the system
alias show_fs_usage_top="sudo fs_usage -w -t 5 -f filesys | tee fs_usage.log | egrep -o '(/.+?) {3}' | sed -e 's/\/dev\/disk[^ ]+  //' | sort | uniq -c | sort -nr | head -10"

alias batlog='bat --pager=never -l log --color=always'
alias tk=task
