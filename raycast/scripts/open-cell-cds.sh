#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title CDS Overview
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

use_cell "$1"

open_grafana "https://${GRAFANA_HOST}/d/PfEgf9BVk/cds-overview?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-quantile=0.99&var-logsource=${LOKI_DS}&var-request_operation=\$__all&var-storage_operation=\$__all&var-persistence_operation=\$__all&var-namespace=\$__all&var-deployments=history&var-rate=1m"
