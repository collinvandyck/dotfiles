#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cell Alerts
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell", "optional": false }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

CELL="$(normalize_cell "$1")"

open "https://${GRAFANA_HOST}/explore?schemaVersion=1&panes=%7B%222e4%22:%7B%22datasource%22:%22af7fe237-211e-413e-9723-41a73886bcbb%22,%22queries%22:%5B%7B%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22af7fe237-211e-413e-9723-41a73886bcbb%22%7D,%22editorMode%22:%22code%22,%22exemplar%22:true,%22expr%22:%22ALERTS%7Bteam%3D%5C%22cds%5C%22,%20cluster%3D%5C%22${CELL}%5C%22,%20alertstate%3D%5C%22firing%5C%22%7D%22,%22interval%22:%22%22,%22legendFormat%22:%22%7B%7B%20alertname%20%7D%7D%22,%22range%22:true,%22refId%22:%22A%22,%22adhocFilters%22:%5B%5D%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D,%22compact%22:false%7D%7D&orgId=1"
