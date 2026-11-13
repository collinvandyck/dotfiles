#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cell Obs
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell (blank = last)", "optional": true }

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

use_cell "$1"

# overview
open_grafana "https://${GRAFANA_HOST}/d/kb7xn2wqp9ufm8/temporal-cloud-overview?orgId=1&from=now-1h&to=now&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&timezone=utc&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-infra_db_name=${INFRA_DB_NAME}&var-infra_db_datasource=${INFRA_DB_DS}&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99"
# ns
open_grafana "https://${GRAFANA_HOST}/d/namen2wqp9ufsp/temporal-cloud-namespace-overview?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-infra_db_name=${INFRA_DB_NAME}&var-infra_db_datasource=${INFRA_DB_DS}&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99&var-namespaces=\$__all"
# tasks
open_grafana "https://${GRAFANA_HOST}/d/ta7xn2wqp9upro/temporal-cloud-overview-task-processing?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-infra_db_name=${INFRA_DB_NAME}&var-infra_db_datasource=${INFRA_DB_DS}&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99"
# cds
open_grafana "https://${GRAFANA_HOST}/d/PfEgf9BVk/cds-overview?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-logs_datasource=${LOKI_DS}&var-quantile=0.99&var-logsource=${LOKI_DS}&var-request_operation=\$__all&var-storage_operation=\$__all&var-persistence_operation=\$__all&var-namespace=\$__all&var-deployments=history&var-rate=1m&dtab=links"

# oss
open_grafana "https://${GRAFANA_HOST}/d/jh_LXEin2/history?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-service=history-headless&var-quantile=0.99&var-rate=\$__rate_interval&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_VIS_DS}&var-logs_datasource=${LOKI_DS}"
# bossbk
open_grafana "https://${GRAFANA_HOST}/d/9V7duAXVk/boss-bk-zk-stack?orgId=1&var-datasource=${PROM_DS}&var-cluster=${CELL}&var-percentile=0.99&from=now-1h&to=now&timezone=utc&var-namespace=\$__all&dtab=bookie-write-metrics"
# cass
open_grafana "https://${GRAFANA_HOST}/d/e788eea6-8b64-42c1-bbf7-de48e8dfbae9/cassandra?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_ENV}&var-cluster=${CELL}&var-source=${PROM_DS}&var-clickhouse_datasource=${CH_DS}"
# flow control
open_grafana "https://${GRAFANA_HOST}/d/dejp8oai7wxdsd/astra-flowcontrol?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_THANOS_ENV}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_DS}&var-cluster=${CELL}&var-quantile=0.99&var-rate=\$__rate_interval&var-storage_operation=\$__all&var-db=\$__all"
# vis
open_grafana "https://${GRAFANA_HOST}/d/gVq0CdNnk/visibility?orgId=1&from=now-1h&to=now&timezone=utc&var-env=${GRAFANA_THANOS_ENV}&var-datasource=${PROM_DS}&var-clickhouse_datasource=${CH_VIS_DS}&var-logs_datasource=${LOKI_DS}&var-cluster=${CELL}&var-pct=0.99&var-rate=1m&var-ch_rate=60"
