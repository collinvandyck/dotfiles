import { describe, expect, it } from "vitest";

import { matchesFilter, normalizeCell, parseQuery } from "./cell";

describe("normalizeCell", () => {
  it("prefixes a bare cell", () => {
    expect(normalizeCell("aw021")).toBe("s-aw021");
  });

  it("leaves an already-prefixed cell alone", () => {
    expect(normalizeCell("s-aw021")).toBe("s-aw021");
  });

  it("trims surrounding whitespace, including a trailing newline", () => {
    expect(normalizeCell("  aw021\n")).toBe("s-aw021");
  });

  it("keeps an empty cell empty rather than returning a bare prefix", () => {
    expect(normalizeCell("   ")).toBe("");
  });
});

describe("parseQuery", () => {
  it("reads the first token as the cell and the rest as a filter", () => {
    expect(parseQuery("aw021 vis")).toEqual({
      cell: "s-aw021",
      filter: "vis",
    });
  });

  it("lowercases the filter and keeps multi-word filters intact", () => {
    expect(parseQuery("s-aw021 Error Logs").filter).toBe("error logs");
  });

  it("treats a cell with a trailing space as having no filter", () => {
    expect(parseQuery("s-aw021 ")).toEqual({ cell: "s-aw021", filter: "" });
  });

  it("reports no cell for an empty field", () => {
    expect(parseQuery("")).toEqual({ cell: "", filter: "" });
  });
});

describe("matchesFilter", () => {
  it("matches on the title", () => {
    expect(matchesFilter("vis", "Visibility", "list and count queries")).toBe(
      true,
    );
  });

  it("matches on the subtitle", () => {
    expect(matchesFilter("loki", "History Error Logs", "loki, filtered")).toBe(
      true,
    );
  });

  it("rejects a filter that appears in neither", () => {
    expect(matchesFilter("cassandra", "Visibility", "queries")).toBe(false);
  });

  it("keeps everything when the filter is empty", () => {
    expect(matchesFilter("", "Visibility", "queries")).toBe(true);
  });
});
