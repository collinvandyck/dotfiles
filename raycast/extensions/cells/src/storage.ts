// Where each command remembers its last cell. The prod store is ~/.last-cell,
// the same file the raycast shell scripts write from their EXIT trap, so
// picking a cell in either place carries over to the other. Staging cells get
// their own file so one never becomes the default for the prod dashboards.

import { readFileSync, writeFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

import { normalizeCell } from "./cell";
import { parseEnvFile } from "./env";

export interface CellStore {
  // Returns "" when nothing is remembered, which the caller treats as "no cell
  // chosen yet".
  read(): string;
  write(cell: string): void;
}

export const LAST_CELL: CellStore = fileStore(
  join(homedir(), ".last-cell"),
  () => "",
);

// Falls back to CELL in ~/.envrc, the test cell currently in use, until a
// staging cell has been picked.
export const LAST_STAGING_CELL: CellStore = fileStore(
  join(homedir(), ".last-staging-cell"),
  () => readEnvrcCell(join(homedir(), ".envrc")),
);

export function fileStore(path: string, fallback: () => string): CellStore {
  return {
    read: () => readCellFile(path) || fallback(),
    write: (cell) => {
      try {
        writeFileSync(path, `${cell}\n`, "utf8");
      } catch {
        // Losing the memory isn't worth failing the open the user asked for.
      }
    },
  };
}

// Parsed rather than sourced, since ~/.envrc may call direnv stdlib functions.
export function readEnvrcCell(path: string): string {
  try {
    return normalizeCell(parseEnvFile(readFileSync(path, "utf8")).CELL ?? "");
  } catch {
    return "";
  }
}

function readCellFile(path: string): string {
  try {
    return normalizeCell(readFileSync(path, "utf8"));
  } catch {
    return "";
  }
}
