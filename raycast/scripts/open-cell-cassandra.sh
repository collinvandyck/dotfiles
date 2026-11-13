#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cassandra
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

use_cell "$1"

open_grafana "https://${GRAFANA_HOST}/d/e788eea6-8b64-42c1-bbf7-de48e8dfbae9/cassandra?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-source=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-TopN=20"
