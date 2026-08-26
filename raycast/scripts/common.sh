#!/usr/bin/env bash

# Shared helpers for the raycast scripts. Source it with:
#
#   . "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Where the most recently used cell is remembered between runs.
last_cell_file() {
	printf '%s' "${LAST_CELL_FILE:-$HOME/.last-cell}"
}

# Trims surrounding whitespace and prefixes a cell name with "s-" if it isn't
# already there, so " aw021 " and "s-aw021" both come out as "s-aw021".
normalize_cell() {
	local cell="$1"
	cell="${cell#"${cell%%[![:space:]]*}"}"
	cell="${cell%"${cell##*[![:space:]]}"}"
	case "$cell" in
	"" | s-*) printf '%s' "$cell" ;;
	*) printf 's-%s' "$cell" ;;
	esac
}

# Resolves the cell for this run and assigns it to the global CELL. Pass the
# raycast argument; when it's blank the last cell used is read back from
# ~/.last-cell, so "open the same cell again" needs no typing. Exits 1 when
# there's nothing to fall back on.
#
# The resolved cell is written back on exit, but only if the script succeeded —
# a run that bailed on a missing env var shouldn't rewrite the memory. Call it
# directly (use_cell "$1"), never in a command substitution, or the trap lands
# in a subshell that exits immediately.
use_cell() {
	local cell
	cell="$(normalize_cell "$1")"
	if [ -z "$cell" ] && [ -f "$(last_cell_file)" ]; then
		IFS= read -r cell <"$(last_cell_file)" || true
		cell="$(normalize_cell "$cell")"
	fi
	if [ -z "$cell" ]; then
		echo "Cell required (none given, and no last cell remembered)" >&2
		exit 1
	fi
	CELL="$cell"
	trap remember_cell EXIT
}

# EXIT trap installed by use_cell. Preserves the script's exit status.
remember_cell() {
	local status=$?
	[ "$status" -eq 0 ] || return "$status"
	printf '%s\n' "$CELL" >"$(last_cell_file)"
	return "$status"
}
