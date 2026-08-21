#!/usr/bin/env bash

# Shared helpers for the raycast scripts. Source it with:
#
#   . "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Prefixes a cell name with "s-" if it isn't already there, so "aw021" and
# "s-aw021" both come out as "s-aw021".
normalize_cell() {
	local cell="$1"
	case "$cell" in
	"" | s-*) printf '%s' "$cell" ;;
	*) printf 's-%s' "$cell" ;;
	esac
}
