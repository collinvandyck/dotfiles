// The last cell used, kept in ~/.last-cell — the same file the raycast shell
// scripts write from their EXIT trap, so picking a cell in either place carries
// over to the other.

import { readFileSync, writeFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

import { normalizeCell } from "./cell";

export function lastCellPath(): string {
  return join(homedir(), ".last-cell");
}

// Returns "" when the file is missing or empty, which the caller treats the
// same as "no cell chosen yet".
export function readLastCell(): string {
  try {
    return normalizeCell(readFileSync(lastCellPath(), "utf8"));
  } catch {
    return "";
  }
}

export function writeLastCell(cell: string): void {
  try {
    writeFileSync(lastCellPath(), `${cell}\n`, "utf8");
  } catch {
    // Losing the memory isn't worth failing the open the user asked for.
  }
}
