#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cell Overview
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell", "optional": false }

# Reads TEMPORAL_OPS_NAMESPACE from ~/.env
if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

CELL="$1"
open "https://${GRAFANA_HOST}/d/kb7xn2wqp9ufm8/temporal-cloud-overview?orgId=1&from=now-1h&to=now&var-env=prod&var-cluster=${CELL}&timezone=utc&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-infra_db_name=Prod%2FInfraDB&var-infra_db_datasource=c8ea5458-e200-47da-aabc-eea36405a733&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99"
