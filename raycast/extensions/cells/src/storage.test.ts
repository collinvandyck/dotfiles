import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { fileStore, readEnvrcCell } from "./storage";

let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "cells-storage-"));
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

describe("fileStore", () => {
  it("reads back a normalized cell it wrote", () => {
    const store = fileStore(join(dir, "cell"), () => "");
    store.write("s-aw021");
    expect(store.read()).toBe("s-aw021");
    expect(readFileSync(join(dir, "cell"), "utf8")).toBe("s-aw021\n");
  });

  it("uses the fallback while the file is missing", () => {
    const store = fileStore(join(dir, "cell"), () => "s-fallback");
    expect(store.read()).toBe("s-fallback");
  });

  it("prefers the remembered cell over the fallback", () => {
    writeFileSync(join(dir, "cell"), "aw028\n");
    const store = fileStore(join(dir, "cell"), () => "s-fallback");
    expect(store.read()).toBe("s-aw028");
  });
});

describe("readEnvrcCell", () => {
  it("pulls CELL out of an envrc that also calls direnv functions", () => {
    writeFileSync(
      join(dir, ".envrc"),
      "source_up\nexport CELL=cds-collin-261109\nPATH_add bin\n",
    );
    expect(readEnvrcCell(join(dir, ".envrc"))).toBe("s-cds-collin-261109");
  });

  it("returns empty when the envrc is missing", () => {
    expect(readEnvrcCell(join(dir, ".envrc"))).toBe("");
  });
});
