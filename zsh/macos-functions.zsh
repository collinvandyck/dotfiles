# macOS-specific functions
# Extracted from oh-my-zsh macos plugin

# Cross-platform open command
function open_command() {
  local open_cmd

  # define the open command
  case "$OSTYPE" in
    darwin*)  open_cmd='open' ;;
    cygwin*)  open_cmd='cygstart' ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open' || {
                open_cmd='cmd.exe /c start ""'
                [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
                [[ "$1" = (http|https)://* ]] && {
                  1="$(echo "$1" | sed -E 's/([&|()<>^])/^\1/g')" || return 1
                }
              } ;;
    msys*)    open_cmd='start ""' ;;
    *)        echo "Platform $OSTYPE not supported"
              return 1
              ;;
  esac

  # If a URL is passed, $BROWSER might be set to a local browser within SSH.
  if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]; then
    "$BROWSER" "$@"
    return
  fi

  ${=open_cmd} "$@" &>/dev/null
}

# Open in Finder the directories passed as arguments, or the current directory if
# no directories are passed
function ofd {
  if (( ! $# )); then
    open_command $PWD
  else
    open_command $@
  fi
}

# Show/hide hidden files in the Finder
alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Bluetooth restart
function btrestart() {
  sudo kextunload -b com.apple.iokit.BroadcomBluetoothHostControllerUSBTransport
  sudo kextload -b com.apple.iokit.BroadcomBluetoothHostControllerUSBTransport
}