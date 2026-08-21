#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title OSS History
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell", "optional": false }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

CELL="$(normalize_cell "$1")"

open "https://${GRAFANA_HOST}/d/jh_LXEin2/history?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-cluster=${CELL}&var-service=history-headless&var-quantile=0.99&var-rate=\$__rate_interval"
