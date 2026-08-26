#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Cell Workflows
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

use_cell "$1"

# starts-with control plane workflows
open "https://cloud.temporal.io/namespaces/${TEMPORAL_CP_NAMESPACE}/workflows?query=%60WorkflowId%60+STARTS_WITH+%22cell-entity-${CELL}%22"
open "https://cloud.temporal.io/namespaces/${TEMPORAL_TEST_CP_NAMESPACE}/workflows?query=%60WorkflowId%60+STARTS_WITH+%22cell-entity-${CELL}%22"

# infra workflows tagged with cell id
open "https://cloud.temporal.io/namespaces/${TEMPORAL_INFRA_NAMESPACE}/workflows?query=%60CellId%60%3D%22${CELL}%22"
