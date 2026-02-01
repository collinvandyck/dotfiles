# ruf: repeat-until-fail
ruf() {
    while :; do
        "$@" || return $?
    done
}

# wh: display source/definition of command, function, or alias
wh() {
    if [[ $# != 1 ]]; then
        echo "usage: wh [ident]"
        return 1
    fi

    local name="$1"
    local type_output=$(whence -w "$name" 2>/dev/null)
    if [[ -z "$type_output" ]]; then
        echo "$name: not found"
        return 1
    fi

    # Extract just the type (everything after ": ")
    local type_name="${type_output#*: }"

    case "$type_name" in
        command)
            # It's a command, get its path
            local cmd_path=$(whence -p "$name")
            if [[ -f "$cmd_path" ]]; then
                bat "$cmd_path"
            else
                echo "$name is a command but not a file"
                return 1
            fi
            ;;
        function)
            # It's a function, print its definition
            {
                echo "# Function: $name"
                functions "$name"
            } | bat --language=sh
            ;;
        alias)
            # It's an alias, print its definition
            {
                echo "# Alias: $name"
                alias "$name"
            } | bat --language=sh
            ;;
        builtin)
            echo "$name is a shell builtin (no source to display)"
            return 1
            ;;
        reserved)
            echo "$name is a reserved word (no source to display)"
            return 1
            ;;
        *)
            echo "$name: unknown type $type_name"
            return 1
            ;;
    esac
}
