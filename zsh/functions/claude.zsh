cldsp() {
    claude "$@" --allow-dangerously-skip-permissions --dangerously-skip-permissions
}

clcdsp() {
    claude --continue "$@" --allow-dangerously-skip-permissions --dangerously-skip-permissions
}

clrdsp() {
    claude --resume "$@" --allow-dangerously-skip-permissions --dangerously-skip-permissions
}
