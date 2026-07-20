import { describe, it, expect } from "vitest";
import {
  timeRangeToCutoff,
  nextTimeRange,
  buildSearchURL,
  sortStories,
  toStory,
  isNewsStory,
  type Story,
} from "./hn";

// A fixed "now" keeps the time-window cases deterministic.
const NOW = 1_700_000_000;
const DAY = 86_400;

const baseHit = {
  objectID: "1",
  title: "T",
  url: "https://example.com",
  author: "pg",
  points: 1,
  num_comments: 0,
  created_at_i: NOW,
};

describe("timeRangeToCutoff", () => {
  it("returns null for 'all' so no time filter is applied", () => {
    expect(timeRangeToCutoff("all", NOW)).toBeNull();
  });

  it("subtracts 24 hours for '24h'", () => {
    expect(timeRangeToCutoff("24h", NOW)).toBe(NOW - DAY);
  });

  it("subtracts 7 days for 'week'", () => {
    expect(timeRangeToCutoff("week", NOW)).toBe(NOW - 7 * DAY);
  });

  it("subtracts 30 days for 'month'", () => {
    expect(timeRangeToCutoff("month", NOW)).toBe(NOW - 30 * DAY);
  });

  it("subtracts 365 days for 'year'", () => {
    expect(timeRangeToCutoff("year", NOW)).toBe(NOW - 365 * DAY);
  });
});

describe("buildSearchURL", () => {
  it("targets the Algolia story search endpoint", () => {
    const url = new URL(
      buildSearchURL({ query: "rust", range: "week", nowSeconds: NOW }),
    );
    expect(url.origin + url.pathname).toBe(
      "https://hn.algolia.com/api/v1/search",
    );
    expect(url.searchParams.get("tags")).toBe("story");
  });

  it("passes the query through", () => {
    const url = new URL(
      buildSearchURL({ query: "rust lang", range: "week", nowSeconds: NOW }),
    );
    expect(url.searchParams.get("query")).toBe("rust lang");
  });

  it("adds a created_at_i lower bound for a bounded range", () => {
    const url = new URL(
      buildSearchURL({ query: "rust", range: "24h", nowSeconds: NOW }),
    );
    expect(url.searchParams.get("numericFilters")).toBe(
      `created_at_i>${NOW - DAY}`,
    );
  });

  it("omits numericFilters when range is 'all'", () => {
    const url = new URL(
      buildSearchURL({ query: "rust", range: "all", nowSeconds: NOW }),
    );
    expect(url.searchParams.has("numericFilters")).toBe(false);
  });

  it("defaults hitsPerPage to 50", () => {
    const url = new URL(
      buildSearchURL({ query: "rust", range: "week", nowSeconds: NOW }),
    );
    expect(url.searchParams.get("hitsPerPage")).toBe("50");
  });

  it("stays fuzzy by default — no typo or prefix tightening", () => {
    const url = new URL(
      buildSearchURL({ query: "rust", range: "week", nowSeconds: NOW }),
    );
    expect(url.searchParams.has("typoTolerance")).toBe(false);
    expect(url.searchParams.has("queryType")).toBe(false);
  });

  it("tightens to exact matches when match is 'exact'", () => {
    const url = new URL(
      buildSearchURL({
        query: "rust",
        range: "week",
        nowSeconds: NOW,
        match: "exact",
      }),
    );
    expect(url.searchParams.get("typoTolerance")).toBe("false");
    expect(url.searchParams.get("queryType")).toBe("prefixNone");
  });
});

describe("nextTimeRange", () => {
  it("advances to the next range in order", () => {
    expect(nextTimeRange("24h")).toBe("week");
    expect(nextTimeRange("week")).toBe("month");
    expect(nextTimeRange("month")).toBe("year");
    expect(nextTimeRange("year")).toBe("all");
  });

  it("wraps from the last range back to the first", () => {
    expect(nextTimeRange("all")).toBe("24h");
  });
});

describe("sortStories", () => {
  const stories = [
    story({ id: "a", points: 10, comments: 5 }),
    story({ id: "b", points: 50, comments: 1 }),
    story({ id: "c", points: 20, comments: 99 }),
  ];

  it("orders by points descending", () => {
    expect(sortStories(stories, "points").map((s) => s.id)).toEqual([
      "b",
      "c",
      "a",
    ]);
  });

  it("orders by comments descending", () => {
    expect(sortStories(stories, "comments").map((s) => s.id)).toEqual([
      "c",
      "a",
      "b",
    ]);
  });

  it("does not mutate the input", () => {
    const input = [...stories];
    sortStories(input, "points");
    expect(input.map((s) => s.id)).toEqual(["a", "b", "c"]);
  });
});

describe("toStory", () => {
  it("maps an external-link story to its article and discussion URLs", () => {
    const s = toStory({
      objectID: "42",
      title: "A title",
      url: "https://example.com/post",
      author: "pg",
      points: 7,
      num_comments: 3,
      created_at_i: NOW,
    });
    expect(s).toEqual({
      id: "42",
      title: "A title",
      articleUrl: "https://example.com/post",
      discussionUrl: "https://news.ycombinator.com/item?id=42",
      points: 7,
      comments: 3,
      author: "pg",
      createdAt: NOW,
    });
  });

  it("leaves articleUrl null for a story with no external link (Ask HN)", () => {
    const s = toStory({
      objectID: "42",
      title: "Ask HN: something",
      url: null,
      author: "pg",
      points: 1,
      num_comments: 0,
      created_at_i: NOW,
    });
    expect(s.articleUrl).toBeNull();
    expect(s.discussionUrl).toBe("https://news.ycombinator.com/item?id=42");
  });

  it("defaults missing points and comments to 0", () => {
    const s = toStory({
      objectID: "42",
      title: "T",
      url: null,
      author: "pg",
      created_at_i: NOW,
    });
    expect(s.points).toBe(0);
    expect(s.comments).toBe(0);
  });
});

describe("isNewsStory", () => {
  it("keeps a plain story", () => {
    expect(
      isNewsStory({ ...baseHit, _tags: ["story", "author_pg", "story_1"] }),
    ).toBe(true);
  });

  it("drops Show HN", () => {
    expect(isNewsStory({ ...baseHit, _tags: ["story", "show_hn"] })).toBe(
      false,
    );
  });

  it("drops Ask HN", () => {
    expect(isNewsStory({ ...baseHit, _tags: ["story", "ask_hn"] })).toBe(false);
  });

  it("drops polls", () => {
    expect(isNewsStory({ ...baseHit, _tags: ["story", "poll"] })).toBe(false);
  });

  it("keeps a hit that has no _tags", () => {
    expect(isNewsStory({ ...baseHit })).toBe(true);
  });
});

function story(overrides: Partial<Story>): Story {
  return {
    id: "id",
    title: "title",
    articleUrl: null,
    discussionUrl: "https://news.ycombinator.com/item?id=id",
    points: 0,
    comments: 0,
    author: "author",
    createdAt: NOW,
    ...overrides,
  };
}
