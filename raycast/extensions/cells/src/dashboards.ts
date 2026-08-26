// Every link the raycast cell scripts open, as URL builders taking a cell. Pure
// — no @raycast/api, no fs — so the whole catalog is unit-testable.

import type { Env } from "./env";

// Grafana datasource UIDs. They're per-org constants, not per-cell, so they
// live here rather than in ~/.env.
const PROMETHEUS = "af7fe237-211e-413e-9723-41a73886bcbb";
const CLICKHOUSE = "aey7czk2sodtse";
// A second clickhouse datasource, used by the visibility and OSS dashboards.
const CLICKHOUSE_VIS = "a1c8349c-753a-4a4c-b2b9-71e3f927e6cb";
const LOKI = "e008932a-e9dc-4b7a-819f-68b662f3dc51";
const INFRA_DB = "c8ea5458-e200-47da-aabc-eea36405a733";

export interface Dashboard {
  id: string;
  title: string;
  subtitle: string;
  // Most entries return one URL; the bundles return several.
  urls(cell: string, env: Env): string[];
}

// The dashboards, in the order they show up in the list. "Cell Obs" leads
// because it's the everything-at-once entry.
export const DASHBOARDS: Dashboard[] = [
  {
    id: "obs",
    title: "Cell Obs",
    subtitle: "every dashboard at once",
    urls: (cell, env) =>
      OBS_BUNDLE.flatMap((id) => dashboard(id).urls(cell, env)),
  },
  {
    id: "overview",
    title: "Cell Overview",
    subtitle: "temporal cloud overview",
    urls: (cell, env) => [
      grafana(env, "/d/kb7xn2wqp9ufm8/temporal-cloud-overview", {
        ...base(cell),
        "var-infra_db_name": "Prod/InfraDB",
        "var-infra_db_datasource": INFRA_DB,
        "var-rate": "$__rate_interval",
        "var-deployments": ["frontend", "matching", "history"],
        "var-quantile": "0.99",
      }),
    ],
  },
  {
    id: "namespaces",
    title: "Namespace Overview",
    subtitle: "per-namespace traffic",
    urls: (cell, env) => [
      grafana(env, "/d/namen2wqp9ufsp/temporal-cloud-namespace-overview", {
        ...base(cell),
        "var-infra_db_name": "Prod/InfraDB",
        "var-infra_db_datasource": INFRA_DB,
        "var-rate": "$__rate_interval",
        "var-deployments": ["frontend", "matching", "history"],
        "var-quantile": "0.99",
        "var-namespaces": "$__all",
      }),
    ],
  },
  {
    id: "tasks",
    title: "Task Processing",
    subtitle: "queues and task lag",
    urls: (cell, env) => [
      grafana(
        env,
        "/d/ta7xn2wqp9upro/temporal-cloud-overview-task-processing",
        {
          ...base(cell),
          "var-infra_db_name": "Prod/InfraDB",
          "var-infra_db_datasource": INFRA_DB,
          "var-rate": "$__rate_interval",
          "var-deployments": ["frontend", "matching", "history"],
          "var-quantile": "0.99",
        },
      ),
    ],
  },
  {
    id: "cds",
    title: "CDS Overview",
    subtitle: "persistence layer",
    urls: (cell, env) => [
      grafana(env, "/d/PfEgf9BVk/cds-overview", {
        ...base(cell),
        "var-quantile": "0.99",
        "var-logsource": LOKI,
        "var-request_operation": "$__all",
        "var-storage_operation": "$__all",
        "var-persistence_operation": "$__all",
        "var-namespace": "$__all",
        "var-deployments": "history",
        "var-rate": "1m",
      }),
    ],
  },
  {
    id: "history",
    title: "OSS History",
    subtitle: "history service",
    urls: (cell, env) => [
      grafana(env, "/d/jh_LXEin2/history", {
        ...base(cell),
        "var-service": "history-headless",
        "var-quantile": "0.99",
        "var-rate": "$__rate_interval",
      }),
    ],
  },
  {
    id: "visibility",
    title: "Visibility",
    subtitle: "list and count queries",
    urls: (cell, env) => [
      grafana(env, "/d/gVq0CdNnk/visibility", {
        ...base(cell),
        "var-env": "prod thanos",
        "var-clickhouse_datasource": CLICKHOUSE_VIS,
        "var-pct": "0.99",
        "var-rate": "1m",
        "var-ch_rate": "60",
      }),
    ],
  },
  {
    id: "bookkeeper",
    title: "Boss / BK / ZK Stack",
    subtitle: "bookie write metrics",
    urls: (cell, env) => [
      grafana(env, "/d/9V7duAXVk/boss-bk-zk-stack", {
        orgId: "1",
        from: "now-1h",
        to: "now",
        timezone: "utc",
        "var-datasource": PROMETHEUS,
        "var-cluster": cell,
        "var-percentile": "0.99",
        "var-namespace": "$__all",
        dtab: "bookie-write-metrics",
      }),
    ],
  },
  {
    id: "cassandra",
    title: "Cassandra",
    subtitle: "ring health",
    urls: (cell, env) => [
      grafana(env, "/d/e788eea6-8b64-42c1-bbf7-de48e8dfbae9/cassandra", {
        orgId: "1",
        from: "now-1h",
        to: "now",
        timezone: "utc",
        "var-env": "prod",
        "var-cluster": cell,
        // This one names the prometheus datasource var-source, not var-datasource.
        "var-source": PROMETHEUS,
        "var-clickhouse_datasource": CLICKHOUSE,
      }),
    ],
  },
  {
    id: "flow-control",
    title: "Astra Flow Control",
    subtitle: "shedding and backpressure",
    urls: (cell, env) => [
      grafana(env, "/d/dejp8oai7wxdsd/astra-flowcontrol", {
        ...base(cell),
        "var-env": "prod thanos",
        "var-quantile": "0.99",
        "var-rate": "$__rate_interval",
        "var-storage_operation": "$__all",
        "var-db": "$__all",
      }),
    ],
  },
  {
    id: "rate-limits",
    title: "Rate Limits",
    subtitle: "throttling by namespace",
    urls: (cell, env) => [
      grafana(env, "/d/fecvva5moraz3e/rate-limits", {
        ...base(cell),
        "var-namespaces": "$__all",
        "var-infra_db_name": "Prod/InfraDB",
        "var-infra_db_datasource": INFRA_DB,
        "var-rate": "$__rate_interval",
        "var-deployments": ["frontend", "matching", "history"],
      }),
    ],
  },
  {
    id: "alerts",
    title: "Firing Alerts",
    subtitle: "cds alerts, explore",
    urls: (cell, env) => [
      promExplore(
        env,
        `ALERTS{team="cds", cluster="${cell}", alertstate="firing"}`,
        "{{ alertname }}",
      ),
    ],
  },
  {
    id: "persistence-errors",
    title: "Persistence Errors",
    subtitle: "error rate by namespace, explore",
    urls: (cell, env) => [
      promExplore(
        env,
        `sum by (temporal_namespace) (rate(persistence_errors{cluster="${cell}", service_name="history"}[$__rate_interval]))`,
        "{{ database_name }}",
      ),
    ],
  },
  {
    id: "error-logs",
    title: "History Error Logs",
    subtitle: "loki, deadline exceeded filtered out",
    urls: (cell, env) => [historyErrorLogs(cell, env)],
  },
  {
    id: "workflows",
    title: "Cell Workflows",
    subtitle: "control plane and infra workflows",
    urls: (cell, env) => [
      cloudWorkflows(
        env.cpNamespace,
        `\`WorkflowId\` STARTS_WITH "cell-entity-${cell}"`,
      ),
      cloudWorkflows(
        env.testCpNamespace,
        `\`WorkflowId\` STARTS_WITH "cell-entity-${cell}"`,
      ),
      cloudWorkflows(env.infraNamespace, `\`CellId\`="${cell}"`),
    ],
  },
];

// What "Cell Obs" opens, matching the old cell-obs.sh.
const OBS_BUNDLE = [
  "overview",
  "namespaces",
  "tasks",
  "cds",
  "history",
  "bookkeeper",
  "cassandra",
  "flow-control",
  "visibility",
];

export function dashboard(id: string): Dashboard {
  const found = DASHBOARDS.find((d) => d.id === id);
  if (!found) {
    throw new Error(`unknown dashboard: ${id}`);
  }
  return found;
}

type Params = Record<string, string | string[]>;

// The parameters nearly every cell dashboard takes. Spread it first so an entry
// can override a value (visibility uses a different clickhouse datasource).
function base(cell: string): Params {
  return {
    orgId: "1",
    from: "now-1h",
    to: "now",
    timezone: "utc",
    "var-env": "prod",
    "var-cluster": cell,
    "var-datasource": PROMETHEUS,
    "var-clickhouse_datasource": CLICKHOUSE,
    "var-logs_datasource": LOKI,
  };
}

function grafana(env: Env, path: string, params: Params): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    for (const one of Array.isArray(value) ? value : [value]) {
      search.append(key, one);
    }
  }
  // URLSearchParams writes spaces as "+", which only means a space to a parser
  // doing form decoding. The shell scripts sent %20 and grafana is happy with
  // it, so keep that. A literal "+" in a value is already %2B by this point.
  const query = search.toString().replace(/\+/g, "%20");
  return `https://${env.grafanaHost}${path}?${query}`;
}

// Grafana's Explore takes its whole state as one url-encoded JSON blob.
function explore(env: Env, panes: unknown): string {
  const encoded = encodeURIComponent(JSON.stringify(panes));
  return `https://${env.grafanaHost}/explore?schemaVersion=1&panes=${encoded}&orgId=1`;
}

function promExplore(env: Env, expr: string, legendFormat: string): string {
  return explore(env, {
    "2e4": {
      datasource: PROMETHEUS,
      queries: [
        {
          datasource: { type: "prometheus", uid: PROMETHEUS },
          editorMode: "code",
          exemplar: true,
          expr,
          interval: "",
          legendFormat,
          range: true,
          refId: "A",
          adhocFilters: [],
        },
      ],
      range: { from: "now-1h", to: "now" },
      compact: false,
    },
  });
}

function historyErrorLogs(cell: string, env: Env): string {
  const uid = env.historyLogsDatasourceUid;
  const expr = [
    `{cluster="${cell}", k8s_component="history"}`,
    "!= `context deadline exceeded`",
    '|= `"level":"error"`',
    "| json",
  ].join("\n");
  return explore(env, {
    "prod-history-logs": {
      datasource: uid,
      queries: [
        {
          refId: "A",
          expr,
          queryType: "range",
          datasource: { type: "loki", uid },
          editorMode: "code",
          direction: "forward",
        },
      ],
      range: { from: "now-1h", to: "now" },
      panelsState: { logs: { sortOrder: "Ascending" } },
      compact: false,
    },
  });
}

function cloudWorkflows(namespace: string, query: string): string {
  return `https://cloud.temporal.io/namespaces/${namespace}/workflows?query=${encodeURIComponent(query)}`;
}
