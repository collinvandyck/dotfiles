#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cell Namespace Overview
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

use_cell "$1"

open_grafana "https://${GRAFANA_HOST}/d/namen2wqp9ufsp/temporal-cloud-namespace-overview?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-infra_db_name=${INFRA_DB_NAME}&var-infra_db_datasource=${INFRA_DB_DS}&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99&var-namespaces=\$__all"
