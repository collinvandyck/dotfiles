import { describe, expect, it } from "vitest";

import { DASHBOARDS, dashboard } from "./dashboards";
import type { Env } from "./env";

const ENV: Env = {
  grafanaHost: "grafana.example",
  cpNamespace: "prod.cp",
  testCpNamespace: "test.cp",
  infraNamespace: "prod.infra",
  historyLogsDatasourceUid: "loki-uid",
};

const CELL = "s-aw021";

// Pulls the JSON back out of an Explore link so the query can be asserted on
// without matching percent-encoding by hand.
function panes(url: string): Record<string, { queries: { expr: string }[] }> {
  const encoded = new URL(url).searchParams.get("panes");
  return JSON.parse(encoded ?? "{}");
}

describe("the catalog", () => {
  it("gives every dashboard a unique id", () => {
    const ids = DASHBOARDS.map((d) => d.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it.each(DASHBOARDS.map((d) => [d.id, d] as const))(
    "%s builds urls that name the cell",
    (_id, d) => {
      const urls = d.urls(CELL, ENV);
      expect(urls.length).toBeGreaterThan(0);
      for (const url of urls) {
        expect(url).toContain(CELL);
        expect(() => new URL(url)).not.toThrow();
      }
    },
  );
});

describe("cell obs", () => {
  it("opens one tab per bundled dashboard", () => {
    expect(dashboard("obs").urls(CELL, ENV)).toHaveLength(9);
  });

  it("includes the cds overview it bundles", () => {
    const [cds] = dashboard("cds").urls(CELL, ENV);
    expect(dashboard("obs").urls(CELL, ENV)).toContain(cds);
  });
});

describe("grafana dashboards", () => {
  it("points the cds overview at the cell on the configured host", () => {
    const url = new URL(dashboard("cds").urls(CELL, ENV)[0]);
    expect(url.host).toBe("grafana.example");
    expect(url.pathname).toBe("/d/PfEgf9BVk/cds-overview");
    expect(url.searchParams.get("var-cluster")).toBe(CELL);
    expect(url.searchParams.get("var-rate")).toBe("1m");
  });

  it("repeats var-deployments once per service on the overview", () => {
    const url = new URL(dashboard("overview").urls(CELL, ENV)[0]);
    expect(url.searchParams.getAll("var-deployments")).toEqual([
      "frontend",
      "matching",
      "history",
    ]);
  });

  it("uses the visibility clickhouse datasource on the visibility board", () => {
    const url = new URL(dashboard("visibility").urls(CELL, ENV)[0]);
    expect(url.searchParams.get("var-clickhouse_datasource")).toBe(
      "a1c8349c-753a-4a4c-b2b9-71e3f927e6cb",
    );
    expect(url.searchParams.get("var-env")).toBe("prod thanos");
  });

  it("percent-encodes spaces rather than writing them as plus signs", () => {
    const [url] = dashboard("visibility").urls(CELL, ENV);
    expect(url).toContain("var-env=prod%20thanos");
    expect(url).not.toContain("+");
  });

  it("names the cassandra datasource var-source", () => {
    const url = new URL(dashboard("cassandra").urls(CELL, ENV)[0]);
    expect(url.searchParams.get("var-source")).toBe(
      "af7fe237-211e-413e-9723-41a73886bcbb",
    );
  });
});

describe("explore links", () => {
  it("scopes the alerts query to the cell and the cds team", () => {
    const [url] = dashboard("alerts").urls(CELL, ENV);
    expect(panes(url)["2e4"].queries[0].expr).toBe(
      `ALERTS{team="cds", cluster="${CELL}", alertstate="firing"}`,
    );
  });

  it("rates persistence errors by namespace", () => {
    const [url] = dashboard("persistence-errors").urls(CELL, ENV);
    expect(panes(url)["2e4"].queries[0].expr).toBe(
      `sum by (temporal_namespace) (rate(persistence_errors{cluster="${CELL}", service_name="history"}[$__rate_interval]))`,
    );
  });

  it("filters deadline-exceeded noise out of the history logs", () => {
    const [url] = dashboard("error-logs").urls(CELL, ENV);
    const expr = panes(url)["prod-history-logs"].queries[0].expr;
    expect(expr).toContain(`{cluster="${CELL}", k8s_component="history"}`);
    expect(expr).toContain("!= `context deadline exceeded`");
    expect(expr).toContain('|= `"level":"error"`');
  });
});

describe("workflow links", () => {
  it("queries each namespace from ~/.env", () => {
    const urls = dashboard("workflows").urls(CELL, ENV);
    expect(urls.map((u) => new URL(u).pathname)).toEqual([
      "/namespaces/prod.cp/workflows",
      "/namespaces/test.cp/workflows",
      "/namespaces/prod.infra/workflows",
    ]);
  });

  it("matches control plane workflows by cell-entity prefix", () => {
    const [cp] = dashboard("workflows").urls(CELL, ENV);
    expect(new URL(cp).searchParams.get("query")).toBe(
      `\`WorkflowId\` STARTS_WITH "cell-entity-${CELL}"`,
    );
  });

  it("matches infra workflows by cell id", () => {
    const infra = dashboard("workflows").urls(CELL, ENV)[2];
    expect(new URL(infra).searchParams.get("query")).toBe(
      `\`CellId\`="${CELL}"`,
    );
  });
});
