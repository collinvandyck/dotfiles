use_chruby() {
    if command -v brew &>/dev/null; then
        source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
        source "$(brew --prefix)/opt/chruby/share/chruby/auto.sh"
        return 0
    fi
    if [[ -f /usr/local/share/chruby/chruby.sh ]]; then
        source /usr/local/share/chruby/chruby.sh
        source /usr/local/share/chruby/auto.sh
        return 0
    fi
}
