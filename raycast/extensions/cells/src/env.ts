// Reads the same ~/.env the raycast shell scripts source, so the extension and
// the scripts stay configured from one place.

import { readFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

export interface Env {
  grafanaHost: string;
  cpNamespace: string;
  testCpNamespace: string;
  infraNamespace: string;
  historyLogsDatasourceUid: string;
}

// Parses the subset of shell syntax that actually shows up in ~/.env: comments,
// blank lines, an optional `export`, and values that may be quoted. Anything
// fancier (command substitution, references to other variables) is left as the
// literal text, which is wrong but visibly wrong.
export function parseEnvFile(text: string): Record<string, string> {
  const vars: Record<string, string> = {};
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) {
      continue;
    }
    const match = /^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/.exec(trimmed);
    if (!match) {
      continue;
    }
    const [, name, rawValue] = match;
    vars[name] = unquote(rawValue.trim());
  }
  return vars;
}

export class MissingEnvError extends Error {
  constructor(public readonly name: string) {
    super(`Set ${name} in ~/.env`);
  }
}

// Loads ~/.env and pulls out what the dashboards need. Throws MissingEnvError
// for the one value nothing works without; the namespace variables are only
// needed by the workflow links, so a blank there degrades to a broken link
// rather than an unusable command.
export function loadEnv(path = join(homedir(), ".env")): Env {
  let text = "";
  try {
    text = readFileSync(path, "utf8");
  } catch {
    throw new MissingEnvError("GRAFANA_HOST");
  }
  const vars = parseEnvFile(text);
  if (!vars.GRAFANA_HOST) {
    throw new MissingEnvError("GRAFANA_HOST");
  }
  return {
    grafanaHost: vars.GRAFANA_HOST,
    cpNamespace: vars.TEMPORAL_CP_NAMESPACE ?? "",
    testCpNamespace: vars.TEMPORAL_TEST_CP_NAMESPACE ?? "",
    infraNamespace: vars.TEMPORAL_INFRA_NAMESPACE ?? "",
    historyLogsDatasourceUid: vars.HISTORY_LOGS_DATASOURCE_UID ?? "",
  };
}

function unquote(value: string): string {
  const quoted =
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"));
  return quoted && value.length >= 2 ? value.slice(1, -1) : value;
}
