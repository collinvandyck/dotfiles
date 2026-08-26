import { describe, expect, it } from "vitest";

import { parseEnvFile } from "./env";

describe("parseEnvFile", () => {
  it("reads plain assignments", () => {
    expect(parseEnvFile("GRAFANA_HOST=grafana.example")).toEqual({
      GRAFANA_HOST: "grafana.example",
    });
  });

  it("strips an export prefix and surrounding quotes", () => {
    expect(parseEnvFile(`export TEMPORAL_CP_NAMESPACE="prod.cp"`)).toEqual({
      TEMPORAL_CP_NAMESPACE: "prod.cp",
    });
  });

  it("skips comments and blank lines", () => {
    const vars = parseEnvFile("# a comment\n\nA=1\n");
    expect(vars).toEqual({ A: "1" });
  });

  it("keeps a value containing an equals sign whole", () => {
    expect(parseEnvFile("TOKEN=abc=def").TOKEN).toBe("abc=def");
  });

  it("ignores lines that aren't assignments", () => {
    expect(parseEnvFile("if [ -f x ]; then\nA=1")).toEqual({ A: "1" });
  });
});
