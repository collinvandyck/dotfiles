#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title OSS History
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

use_cell "$1"

open_grafana "https://${GRAFANA_HOST}/d/jh_LXEin2/history?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-cluster=${CELL}&var-service=history-headless&var-quantile=0.99&var-rate=\$__rate_interval"
