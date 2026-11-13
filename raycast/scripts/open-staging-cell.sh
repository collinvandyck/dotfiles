#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Staging Cell
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last staging)", "optional": true }

CELL_PROFILE=staging exec "$(dirname "${BASH_SOURCE[0]}")/open-cell-so.sh" "$@"
