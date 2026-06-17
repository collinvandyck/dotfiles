#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cell Obs
# @raycast.mode silent
#
# Optional parameters:
# @raycast.packageName Temporal
# @raycast.argument1 { "type": "text", "placeholder": "cell", "optional": false }

if [ -f "$HOME/.env" ]; then . "$HOME/.env"; fi

CELL="$1"

# overview
open "https://${GRAFANA_HOST}/d/kb7xn2wqp9ufm8/temporal-cloud-overview?orgId=1&from=now-1h&to=now&var-env=prod&var-cluster=${CELL}&timezone=utc&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-infra_db_name=Prod%2FInfraDB&var-infra_db_datasource=c8ea5458-e200-47da-aabc-eea36405a733&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99"
# ns
open "https://${GRAFANA_HOST}/d/namen2wqp9ufsp/temporal-cloud-namespace-overview?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod&var-cluster=${CELL}&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-infra_db_name=Prod%2FInfraDB&var-infra_db_datasource=c8ea5458-e200-47da-aabc-eea36405a733&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99&var-namespaces=\$__all"
# tasks
open "https://${GRAFANA_HOST}/d/ta7xn2wqp9upro/temporal-cloud-overview-task-processing?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod&var-cluster=${CELL}&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-infra_db_name=Prod%2FInfraDB&var-infra_db_datasource=c8ea5458-e200-47da-aabc-eea36405a733&var-rate=\$__rate_interval&var-deployments=frontend&var-deployments=matching&var-deployments=history&var-quantile=0.99"
# cds
open "https://${GRAFANA_HOST}/d/PfEgf9BVk/cds-overview?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod&var-cluster=${CELL}&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-quantile=0.99&var-logsource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-request_operation=\$__all&var-storage_operation=\$__all&var-persistence_operation=\$__all&var-namespace=\$__all&var-deployments=history&var-rate=1m&dtab=links"

# oss
open "https://${GRAFANA_HOST}/d/jh_LXEin2/history?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod&var-cluster=${CELL}&var-service=history-headless&var-quantile=0.99&var-rate=\$__rate_interval&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=a1c8349c-753a-4a4c-b2b9-71e3f927e6cb&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51"
# bossbk
open "https://${GRAFANA_HOST}/d/9V7duAXVk/boss-bk-zk-stack?orgId=1&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-cluster=${CELL}&var-percentile=0.99&from=now-1h&to=now&timezone=utc&var-namespace=\$__all&dtab=bookie-write-metrics"
# cass
open "https://${GRAFANA_HOST}/d/e788eea6-8b64-42c1-bbf7-de48e8dfbae9/cassandra?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod&var-cluster=${CELL}&var-source=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse"
# flow control
open "https://${GRAFANA_HOST}/d/dejp8oai7wxdsd/astra-flowcontrol?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod%20thanos&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=aey7czk2sodtse&var-cluster=${CELL}&var-quantile=0.99&var-rate=\$__rate_interval&var-storage_operation=\$__all&var-db=\$__all"
# vis
open "https://${GRAFANA_HOST}/d/gVq0CdNnk/visibility?orgId=1&from=now-1h&to=now&timezone=utc&var-env=prod%20thanos&var-datasource=af7fe237-211e-413e-9723-41a73886bcbb&var-clickhouse_datasource=a1c8349c-753a-4a4c-b2b9-71e3f927e6cb&var-logs_datasource=e008932a-e9dc-4b7a-819f-68b662f3dc51&var-cluster=${CELL}&var-pct=0.99&var-rate=1m&var-ch_rate=60"
