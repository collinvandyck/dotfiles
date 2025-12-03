# only inject context that match this pattern
CT_CONTEXT_SAFE_PATTERN="collin"

ctt() {
    # poor man's aliases (eg kc -> kubectl)
    local -a args=("${@}")
    case "$1" in
        kc) args[1]=kubectl ;;
    esac

    # inject context for these commands
    case "${args[1]}" in
        kubectl) _ct_inject_context ;;
    esac

    ct "${args[@]}" 2> >(_ct_filter_warnings >&2)
}

_ct_inject_context() {
    [[ "$CT_CONTEXT" == *${CT_CONTEXT_SAFE_PATTERN}* ]] || return
    [[ " ${args[*]} " == *" --context "* ]] && return
    args=(kubectl --context "$CT_CONTEXT" "${args[@]:1}")
}

_ct_filter_warnings() {
    rg --line-buffered -v 'warning: no --duration provided|reusing cached approved access|\x1b'
}
