#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cell Visibilty
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (e.g. s-aw028)", "optional": false }

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

CELL="$1"
open "https://${GRAFANA_HOST}/d/gVq0CdNnk/visibility?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod%20thanos&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=a1c8349c-753a-4a4c-b2b9-71e3f927e6cb&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-cluster=${CELL}&var-pct=0.99&var-rate=1m&var-ch_rate=60"
