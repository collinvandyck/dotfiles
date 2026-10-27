#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title So Cell
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

use_cell "$1"

open "https://cloud.temporal.io/support/cells/${CELL}"
