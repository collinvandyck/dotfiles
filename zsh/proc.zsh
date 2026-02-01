# ruf: repeat-until-fail
ruf() {
    while :; do
        "$@" || return $?
    done
}
