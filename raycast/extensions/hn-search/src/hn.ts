// Pure helpers for the HN Algolia search command. Kept free of @raycast/api so
// they can be unit-tested without the Raycast runtime.

export type TimeRange = "24h" | "week" | "month" | "year" | "all";
export type SortMode = "points" | "comments";
export type MatchMode = "fuzzy" | "exact";

export interface Story {
  id: string;
  title: string;
  articleUrl: string | null;
  discussionUrl: string;
  points: number;
  comments: number;
  author: string;
  createdAt: number;
}

// Shape of a hit from https://hn.algolia.com/api/v1/search. Only the fields we
// use are declared; the API returns more.
export interface AlgoliaHit {
  objectID: string;
  title: string;
  url?: string | null;
  author: string;
  points?: number;
  num_comments?: number;
  created_at_i: number;
}

const SEARCH_ENDPOINT = "https://hn.algolia.com/api/v1/search";
const DAY = 86_400;

const RANGE_SECONDS: Record<Exclude<TimeRange, "all">, number> = {
  "24h": DAY,
  week: 7 * DAY,
  month: 30 * DAY,
  year: 365 * DAY,
};

// Lower bound on created_at_i for a range, or null for "all" (no time filter).
export function timeRangeToCutoff(
  range: TimeRange,
  nowSeconds: number,
): number | null {
  if (range === "all") {
    return null;
  }
  return nowSeconds - RANGE_SECONDS[range];
}

export function buildSearchURL(params: {
  query: string;
  range: TimeRange;
  nowSeconds: number;
  match?: MatchMode;
  hitsPerPage?: number;
}): string {
  const {
    query,
    range,
    nowSeconds,
    match = "fuzzy",
    hitsPerPage = 50,
  } = params;
  const search = new URLSearchParams({
    query,
    tags: "story",
    hitsPerPage: String(hitsPerPage),
  });

  const cutoff = timeRangeToCutoff(range, nowSeconds);
  if (cutoff !== null) {
    search.set("numericFilters", `created_at_i>${cutoff}`);
  }

  // Exact turns off Algolia's fuzzy behaviors: typo correction and last-word
  // prefix expansion. Fuzzy leaves Algolia's defaults in place.
  if (match === "exact") {
    search.set("typoTolerance", "false");
    search.set("queryType", "prefixNone");
  }

  return `${SEARCH_ENDPOINT}?${search.toString()}`;
}

// Re-sort a page of stories by the chosen field, descending. Returns a new array.
export function sortStories(stories: Story[], sort: SortMode): Story[] {
  const key = sort === "points" ? "points" : "comments";
  return [...stories].sort((a, b) => b[key] - a[key]);
}

export function toStory(hit: AlgoliaHit): Story {
  return {
    id: hit.objectID,
    title: hit.title,
    articleUrl: hit.url ?? null,
    discussionUrl: `https://news.ycombinator.com/item?id=${hit.objectID}`,
    points: hit.points ?? 0,
    comments: hit.num_comments ?? 0,
    author: hit.author,
    createdAt: hit.created_at_i,
  };
}
