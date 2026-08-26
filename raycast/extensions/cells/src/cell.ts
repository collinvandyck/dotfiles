// Pure helpers for cell names and the combined search field. Kept free of
// @raycast/api and fs so they can be unit-tested without the Raycast runtime.

// Trims surrounding whitespace and prefixes a cell name with "s-" if it isn't
// already there, so " aw021 " and "s-aw021" both come out as "s-aw021". Mirrors
// normalize_cell in raycast/scripts/common.sh.
export function normalizeCell(raw: string): string {
  const cell = raw.trim();
  if (cell === "" || cell.startsWith("s-")) {
    return cell;
  }
  return `s-${cell}`;
}

export interface Query {
  cell: string;
  filter: string;
}

// Splits the search field into the cell and a filter over dashboard names, so
// "aw021 vis" means "the visibility dashboard for s-aw021". The first token is
// always the cell — the field is seeded with the last cell used, so the common
// move is appending a filter to what's already there rather than typing a cell.
export function parseQuery(text: string): Query {
  const [first = "", ...rest] = text.trim().split(/\s+/);
  return { cell: normalizeCell(first), filter: rest.join(" ").toLowerCase() };
}

// Case-insensitive substring match over a dashboard's title and subtitle.
export function matchesFilter(
  filter: string,
  title: string,
  subtitle: string,
): boolean {
  if (filter === "") {
    return true;
  }
  return `${title} ${subtitle}`.toLowerCase().includes(filter);
}
