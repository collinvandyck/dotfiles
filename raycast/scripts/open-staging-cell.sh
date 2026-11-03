#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Staging Cell
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = $CELL from ~/.envrc)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Skips use_cell on purpose so a staging cell never lands in ~/.last-cell, which the prod scripts read.
cell="$(normalize_cell "$1")"

if [ -z "$cell" ]; then
	# Parse CELL out of ~/.envrc rather than sourcing it, since the file may use direnv stdlib functions.
	cell="$(sed -nE 's/^[[:space:]]*(export[[:space:]]+)?CELL=["'\'']?([^"'\''[:space:]]*).*/\2/p' "$HOME/.envrc" 2>/dev/null | tail -n 1)"
	cell="$(normalize_cell "$cell")"
fi

if [ -z "$cell" ]; then
	echo "Cell required (none given, and CELL is not set in ~/.envrc)" >&2
	exit 1
fi

open "https://staging.thundergun.io/support/cells/${cell}"
