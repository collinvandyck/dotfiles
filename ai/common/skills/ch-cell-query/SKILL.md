---
name: ch-cell-query
description: Ad-hoc querying of a live ClickHouse visibility test cell — Prometheus/Thanos metrics and ClickHouse SQL — for write-path discovery and spot-checks. Use when confirming a metric series exists, eyeballing a value mid-sweep, or running one-off SQL against the cell's CH cluster. NOT for capturing full baselines (use ch-deploy's `cmd/baseline` for that).
user-invocable: true
allowed-tools: Bash(omni:*), Bash(curl:*), Bash(pgrep:*), Bash(kill:*), Bash(sleep:*)
argument-hint: "[what you want to query]"
---

# Query a live ClickHouse visibility cell

Ad-hoc access to a CH visibility test cell's **metrics** (federated Thanos Querier) and **data** (ClickHouse SQL). For confirming a series exists, eyeballing a value mid-sweep, or one-off SQL. For full, reproducible write-path baselines, use ch-deploy's `cmd/baseline` (`make -C prod baseline-build`) instead — this skill is the lightweight companion.

The cell name is the kubectl context name and is usually in `$CT_CONTEXT`. Every `kubectl` goes through `omni` (`--duration 8h`); direct `kubectl` will not work.

## Access: port-forwards

Both endpoints need a port-forward. `omni kubectl` is a **wrapper process** — a plain `kill $!` signals only the wrapper and leaks the real child holding the port. Tear down by walking the process subtree.

```sh
CELL="${CT_CONTEXT:?set CELL or CT_CONTEXT to the cell name}"

# Metrics: federated Thanos Querier (Temporal metrics + CH :9363 + cAdvisor, one endpoint)
omni kubectl --duration 8h --context "$CELL" -n monitoring \
  port-forward svc/thanos-query 19090:9090 >/tmp/pf-thanos.log 2>&1 &
PF_THANOS=$!

# Data: a single CH pod's HTTP port (8123). Use a single pod, not svc/clickhouse, for SQL.
omni kubectl --duration 8h --context "$CELL" -n clickhouse \
  port-forward svc/chi-ch-default-0-0 18123:8123 >/tmp/pf-ch.log 2>&1 &
PF_CH=$!

# Wait until each forward actually answers (a fixed `sleep` is flaky — ~8s is
# often needed). Poll instead.
for i in $(seq 1 20); do curl -sf --noproxy '*' -G "http://127.0.0.1:19090/api/v1/query" --data-urlencode 'query=up' >/dev/null 2>&1 && break; sleep 1; done
for i in $(seq 1 20); do curl -sf --noproxy '*' "http://127.0.0.1:18123/?user=default&password=password" --data-binary "SELECT 1" >/dev/null 2>&1 && break; sleep 1; done

# ... queries ...

# Teardown (subtree kill — see note above):
for pid in $PF_THANOS $PF_CH; do
  for c in $(pgrep -P "$pid"); do kill "$c" 2>/dev/null; done
  kill "$pid" 2>/dev/null
done
```

## Metrics: Prometheus HTTP API (via Thanos)

**curl gotchas — all three are required:** GET only (`-G`, else 405); `127.0.0.1` not `localhost`; `--noproxy '*'` (a local proxy shim blocks `localhost`). Pass the query with `--data-urlencode`.

```sh
# instant query
curl -s --noproxy '*' -G "http://127.0.0.1:19090/api/v1/query" \
  --data-urlencode 'query=histogram_quantile(0.99, sum by (le)(rate(visibility_persistence_latency_bucket{visibility_plugin_name="clickhouse"}[5m])))'

# does a series exist? (discovery)
curl -s --noproxy '*' -G "http://127.0.0.1:19090/api/v1/series" \
  --data-urlencode 'match[]=ClickHouseProfileEvents_AsyncInsertQuery{namespace="clickhouse"}'

# what label values exist?
curl -s --noproxy '*' -G "http://127.0.0.1:19090/api/v1/label/visibility_plugin_name/values"
```

### PromQL gotchas

- **Latency series are in SECONDS, no `_seconds` suffix.** `visibility_persistence_latency_bucket` le boundaries run `0.001 … 1000, +Inf`. Don't multiply/divide by 1000.
- **Always filter `visibility_plugin_name`.** CH and ES share the `visibility_*` metric names. `clickhouse` is CH; the ES write twin is `elasticsearch-opt-bulk-processor`; a **third** value `elasticsearch` also exists — exclude it from ES comparisons. An unfiltered query blends all three.
- **`task_*` metrics are blended**, not plugin-tagged — they cover the whole visibility queue (ES + CH inside one `Execute()`). Category tag key is `operation`, matcher `operation=~"VisibilityTask.*"`. Context for the headline, not CH-isolated latency.
- **CH server metrics** carry `namespace="clickhouse"` (`:9363`, 6 pods `chi-ch-default-{0,1}-{0,1,2}`). Replication metrics are `ClickHouseAsyncMetrics_Replicas*`, NOT `ClickHouseMetrics_*`.
- **Error counters are absent when zero.** `commit_errors` / `request_errors` / `corrupted_data` / `persistence_resource_exhausted` emit no series until first incremented — treat an empty result as 0 (`(... ) or vector(0)`).

## Data: ClickHouse SQL via :8123

`kubectl exec` into CH pods is blocked by the omni shim (the `--query` flag gets intercepted). Use the HTTP port-forward. Database is `temporal_visibility`; tables `executions_visibility_open` / `executions_visibility_closed`. Cluster name for `clusterAllReplicas` is `'default'`.

```sh
# logical row count (TabSeparated for clean scripting)
curl -s --noproxy '*' --max-time 20 \
  "http://127.0.0.1:18123/?user=default&password=password&default_format=TabSeparated" \
  --data-binary "SELECT count() FROM temporal_visibility.executions_visibility_open"

# aggregate a system table across all replicas (e.g. async-insert coalescing)
curl -s --noproxy '*' --max-time 20 \
  "http://127.0.0.1:18123/?user=default&password=password&default_format=PrettyCompact" \
  --data-binary "SELECT table, count() AS flushes, sum(rows) AS rows, sum(bytes) AS bytes
                 FROM clusterAllReplicas('default', system.asynchronous_insert_log)
                 WHERE database='temporal_visibility' AND event_time > now() - 600
                 GROUP BY table"
```

- **Row counts: trust SQL, not Prometheus.** Use `count()` on the Distributed tables for logical row counts. The Prometheus metric `TotalRowsOfMergeTreeTables` reads ~100× higher (counts something broader) — don't use it for logical counts.
- **`ON CLUSTER` is rejected** inside the `Replicated`-engine `temporal_visibility` DB — DDL auto-propagates via Keeper. Don't add it.

## Reference: useful series for write-path work

- Caller-facing: `visibility_persistence_latency` (histogram, seconds), `visibility_persistence_requests`.
- BatchProcessor internals: `visibility_batch_processor_{request_latency,request_start_latency,commit_latency,flush_time,batch_size,queued_requests,commits}`.
- CH server-side: `ClickHouseProfileEvents_{InsertedRows,InsertQuery,MergedRows}`, `ClickHouseMetrics_Merge`, `ClickHouseAsyncMetrics_MaxPartCountForPartition`, `ClickHouseAsyncMetrics_Replicas*`.
- Async-insert mechanics (confirm presence on the cell before relying on them): `ClickHouseProfileEvents_{AsyncInsertQuery,AsyncInsertBytes,AsyncInsertRows,FailedAsyncInsertQuery,InsertedParts,DelayedInserts,RejectedInserts}`.
