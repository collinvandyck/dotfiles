# misc

alias tma=tmuxinator
alias copy-ssh-key='cat ~/.ssh/id_rsa.pub | pbcopy'
alias sshctl='ll ~/.ssh/control/'
alias xx='ssh -t 5xx.engineer .dotfiles/bin/tm'
alias ut='ssh -t ubuntu-test tm'
alias appsup='cd ~/Library/Application\ Support'
alias da='direnv allow'
alias cat=bat
alias be='bundle exec'
alias front='cd "$(zoxide query brain-app)" && td'
alias back='cd "$(zoxide query brain-backend)" && td'
alias back2='cd "$(zoxide query brain-backend-2)" && td'
alias b=back
alias f=fe
alias nman='nvim "+Man!"'
alias al='awslocal'
alias d='docker'
alias sf='search-files'
alias mann='helpman'
alias pd-credential="op read 'op://Engineering Integrations/PagerDuty/credential'"
alias zz='exec zsh'
alias m='mise'
alias jl='just -l'
alias by='bat -lyaml'
alias cds='z cds'

alias cl='claude'
alias cld='cl --dangerously-skip-permissions'
alias clc='cl --continue'
alias clr='cl --resume'
alias cl-sonnet='cl --model sonnet'
alias cl-opus='cl --model opus'
alias clsa='cd ~/code/saas-temporal && cl'

[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"

# vim
alias vi=nvim
alias vim=nvim

# rust aliases
alias co='cargo'
alias we='watchexec'
alias wer='we -e rs'
alias wert='we -e rs cargo t'
alias cnr='cargo nextest run'
alias j='just'
alias c='cargo'

# git aliases
alias ci='git ci'
alias cip='git cip'
alias gst='git status'
alias gcav='git add -A && git commit -v'
alias gb='GIT_PAGER= git branch --sort=committerdate'
alias gbfmom='git branch -f main $(git_main_branch)'
alias gf='git fetch'
alias gl='git pull'
alias glr='git pull --rebase'
alias gll='git ll'
alias gllh='gll | hd'
alias glla='git lla'
alias gllah='glla | hd'
alias gllch='gllc | hd'
alias glog='git log'
alias stash='git add -A && git stash'
alias pop='git stash pop'
alias gitk='gitk --all > /dev/null 2>&1 &'
alias gr='git reset'
alias grb='git rebase'
alias gcm='git checkout $(git_main_branch)'
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
alias gd='git diff'
alias gdo='gd origin/$(git rev-parse --abbrev-ref HEAD)'
alias gdos='gdo --stat'
alias gdob='gdo | bat'
alias gdu='gd @{u}'
alias wt=worktrees
alias zp='cd $(git rev-parse --git-common-dir)/..'

# zsh aliases
alias reload='exec zsh'
alias ll='ls -lF'
alias lla='ll -a'
alias llh='ll -h'
alias llr='ls -lrth'
alias r=z #disable r builtin

# k8s things
alias mk='minikube'
alias kcl='kc logs'
alias kclt='kcl -f --tail=10'

# docker stuff
alias dc='docker compose'
alias dcdown='dc down -v -t 0'
alias dcup='dc up -d'
alias dcupb='dc up -d --build'
alias dcupp='dc down -v -t 0; dc up -d --build'
alias dcuppl='dcupp && dclogs'
alias dclogs='dc logs -f'
alias dclogst='dc logs -f --tail 15'
alias dps="docker ps --no-trunc --format '{{.Names}}\t{{.Image}}\t{{.Command}}'"
alias de='docker exec'

# clipboard
if [ ! -f "/usr/bin/pbcopy" ]; then
    alias pbcopy='xsel --clipboard --input'
fi
if [ ! -f "/usr/bin/pbpaste" ]; then
    alias pbpaste='xsel --clipboard --output'
fi

# other
alias nowrap='cut -c -$COLUMNS'

# show the top 10 active files on the system
alias show_fs_usage_top="sudo fs_usage -w -t 5 -f filesys | tee fs_usage.log | egrep -o '(/.+?) {3}' | sed -e 's/\/dev\/disk[^ ]+  //' | sort | uniq -c | sort -nr | head -10"

alias batlog='bat --pager=never -l log --color=always'
alias tk=task

# lsd config
alias ls='lsd --color=always'
alias l='ls -lah'
alias lr='ls -lahr'
alias lt='ls --tree'
alias llt='ll --tree'
alias lld='ll -d'
for i in $(seq 1 9); do
    alias "llt${i}"="ll --tree --depth ${i}"
    alias "lt${i}"="lt --tree --depth ${i}"
done

# hyperfine
alias hf='hyperfine 2>/dev/null'

