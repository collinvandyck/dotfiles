fe() {
    cd ~/code/brain-app
    [ "${1:-}" = "--pull" ] && git pull
    td
    use nvm; nvm use; yarn; yarn dev
}
