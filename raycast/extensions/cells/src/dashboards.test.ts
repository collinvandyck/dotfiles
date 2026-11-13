import { describe, expect, it } from "vitest";

import {
  DASHBOARDS,
  PROD,
  STAGING,
  availableDashboards,
  dashboard,
} from "./dashboards";
import type { Env } from "./env";

const ENV: Env = {
  grafanaHost: "grafana.example",
  cpNamespace: "prod.cp",
  testCpNamespace: "test.cp",
  infraNamespace: "prod.infra",
  testInfraNamespace: "test.infra",
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
      const urls = d.urls(CELL, ENV, PROD);
      expect(urls.length).toBeGreaterThan(0);
      for (const url of urls) {
        expect(url).toContain(CELL);
        expect(() => new URL(url)).not.toThrow();
      }
    },
  );
});

describe("grafana links", () => {
  const grafanaUrls = DASHBOARDS.filter((d) => d.id !== "workflows").flatMap(
    (d) => d.urls(CELL, ENV, PROD).map((url) => [d.id, url] as const),
  );

  it.each(grafanaUrls)("%s refreshes every minute", (_id, url) => {
    expect(new URL(url).searchParams.getAll("refresh")).toEqual(["1m"]);
  });
});

describe("cell obs", () => {
  it("opens one tab per bundled dashboard", () => {
    expect(dashboard("obs").urls(CELL, ENV, PROD)).toHaveLength(9);
  });

  it("includes the cds overview it bundles", () => {
    const [cds] = dashboard("cds").urls(CELL, ENV, PROD);
    expect(dashboard("obs").urls(CELL, ENV, PROD)).toContain(cds);
  });
});

describe("grafana dashboards", () => {
  it("points the cds overview at the cell on the configured host", () => {
    const url = new URL(dashboard("cds").urls(CELL, ENV, PROD)[0]);
    expect(url.host).toBe("grafana.example");
    expect(url.pathname).toBe("/d/PfEgf9BVk/cds-overview");
    expect(url.searchParams.get("var-cluster")).toBe(CELL);
    expect(url.searchParams.get("var-rate")).toBe("1m");
  });

  it("repeats var-deployments once per service on the overview", () => {
    const url = new URL(dashboard("overview").urls(CELL, ENV, PROD)[0]);
    expect(url.searchParams.getAll("var-deployments")).toEqual([
      "frontend",
      "matching",
      "history",
    ]);
  });

  it("uses the visibility clickhouse datasource on the visibility board", () => {
    const url = new URL(dashboard("visibility").urls(CELL, ENV, PROD)[0]);
    expect(url.searchParams.get("var-clickhouse_datasource")).toBe(
      "a1c8349c-753a-4a4c-b2b9-71e3f927e6cb",
    );
    expect(url.searchParams.get("var-env")).toBe("prod thanos");
  });

  it("percent-encodes spaces rather than writing them as plus signs", () => {
    const [url] = dashboard("visibility").urls(CELL, ENV, PROD);
    expect(url).toContain("var-env=prod%20thanos");
    expect(url).not.toContain("+");
  });

  it("names the cassandra datasource var-source", () => {
    const url = new URL(dashboard("cassandra").urls(CELL, ENV, PROD)[0]);
    expect(url.searchParams.get("var-source")).toBe(
      "af7fe237-211e-413e-9723-41a73886bcbb",
    );
  });
});

describe("explore links", () => {
  it("scopes the alerts query to the cell and the cds team", () => {
    const [url] = dashboard("alerts").urls(CELL, ENV, PROD);
    expect(panes(url)["2e4"].queries[0].expr).toBe(
      `ALERTS{team="cds", cluster="${CELL}", alertstate="firing"}`,
    );
  });

  it("rates persistence errors by namespace", () => {
    const [url] = dashboard("persistence-errors").urls(CELL, ENV, PROD);
    expect(panes(url)["2e4"].queries[0].expr).toBe(
      `sum by (temporal_namespace) (rate(persistence_errors{cluster="${CELL}", service_name="history"}[$__rate_interval]))`,
    );
  });

  it("filters deadline-exceeded noise out of the history logs", () => {
    const [url] = dashboard("error-logs").urls(CELL, ENV, PROD);
    const expr = panes(url)["prod-history-logs"].queries[0].expr;
    expect(expr).toContain(`{cluster="${CELL}", k8s_component="history"}`);
    expect(expr).toContain("!= `context deadline exceeded`");
    expect(expr).toContain('|= `"level":"error"`');
  });
});

describe("workflow links", () => {
  it("queries each namespace from ~/.env", () => {
    const urls = dashboard("workflows").urls(CELL, ENV, PROD);
    expect(urls.map((u) => new URL(u).pathname)).toEqual([
      "/namespaces/prod.cp/workflows",
      "/namespaces/test.cp/workflows",
      "/namespaces/prod.infra/workflows",
    ]);
  });

  it("matches control plane workflows by cell-entity prefix", () => {
    const [cp] = dashboard("workflows").urls(CELL, ENV, PROD);
    expect(new URL(cp).searchParams.get("query")).toBe(
      `\`WorkflowId\` STARTS_WITH "cell-entity-${CELL}"`,
    );
  });

  it("matches infra workflows by cell id", () => {
    const infra = dashboard("workflows").urls(CELL, ENV, PROD)[2];
    expect(new URL(infra).searchParams.get("query")).toBe(
      `\`CellId\`="${CELL}"`,
    );
  });
});

describe("staging", () => {
  const STAGING_CELL = "s-cds-collin-261109";

  it.each(availableDashboards(ENV, STAGING).map((d) => [d.id, d] as const))(
    "%s builds urls that name the cell",
    (_id, d) => {
      const urls = d.urls(STAGING_CELL, ENV, STAGING);
      expect(urls.length).toBeGreaterThan(0);
      for (const url of urls) {
        expect(url).toContain(STAGING_CELL);
        expect(() => new URL(url)).not.toThrow();
      }
    },
  );

  it("points the history dashboard at the test datasources", () => {
    const url = new URL(
      dashboard("history").urls(STAGING_CELL, ENV, STAGING)[0],
    );
    expect(url.searchParams.get("var-env")).toBe("dev thanos");
    expect(url.searchParams.get("var-datasource")).toBe(
      "ef667c0e-d08c-4b40-9761-479514828632",
    );
    expect(url.searchParams.get("var-clickhouse_datasource")).toBe(
      "bevsfyywc7hfka",
    );
    expect(url.searchParams.get("var-logs_datasource")).toBe("");
  });

  it("queries the test prometheus from explore", () => {
    const [url] = dashboard("alerts").urls(STAGING_CELL, ENV, STAGING);
    expect(panes(url)["2e4"]).toMatchObject({
      datasource: "ef667c0e-d08c-4b40-9761-479514828632",
    });
  });

  it("queries only the test namespaces for workflows", () => {
    const urls = dashboard("workflows").urls(STAGING_CELL, ENV, STAGING);
    expect(urls.map((u) => new URL(u).pathname)).toEqual([
      "/namespaces/test.cp/workflows",
      "/namespaces/test.infra/workflows",
    ]);
  });

  it("hides the history error logs, which have no staging datasource", () => {
    const ids = availableDashboards(ENV, STAGING).map((d) => d.id);
    expect(ids).not.toContain("error-logs");
    expect(availableDashboards(ENV, PROD).map((d) => d.id)).toContain(
      "error-logs",
    );
  });
});
