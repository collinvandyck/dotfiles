import { useState } from "react";
import { Action, ActionPanel, Icon, List, Keyboard, open } from "@raycast/api";
import { useFetch, useLocalStorage } from "@raycast/utils";
import {
  buildSearchURL,
  isNewsStory,
  nextTimeRange,
  sortStories,
  toStory,
  TIME_RANGE_ORDER,
  type AlgoliaHit,
  type MatchMode,
  type SortMode,
  type Story,
  type TimeRange,
} from "./hn";

interface SearchResponse {
  hits: AlgoliaHit[];
}

const TIME_RANGE_TITLES: Record<TimeRange, string> = {
  "24h": "Last 24 Hours",
  week: "Past Week",
  month: "Past Month",
  year: "Past Year",
  all: "All Time",
};

export default function Command() {
  const [searchText, setSearchText] = useState("");
  // Persisted across launches so the last-picked window and sort stick.
  const {
    value: range = "week",
    setValue: setRange,
    isLoading: isRangeLoading,
  } = useLocalStorage<TimeRange>("time-range", "week");
  const {
    value: sort = "points",
    setValue: setSort,
    isLoading: isSortLoading,
  } = useLocalStorage<SortMode>("sort", "points");
  const {
    value: match = "fuzzy",
    setValue: setMatch,
    isLoading: isMatchLoading,
  } = useLocalStorage<MatchMode>("match", "fuzzy");
  // Fixed at mount so keystrokes don't churn the time window (and the fetch URL).
  const [nowSeconds] = useState(() => Math.floor(Date.now() / 1000));

  const { data, isLoading } = useFetch<SearchResponse>(
    buildSearchURL({ query: searchText, range, nowSeconds, match }),
    {
      // Wait for stored prefs before firing, so we don't flash the defaults.
      execute: !isRangeLoading && !isMatchLoading,
      keepPreviousData: true,
      failureToastOptions: { title: "Could not reach Hacker News" },
    },
  );

  const stories = sortStories(
    (data?.hits ?? []).filter(isNewsStory).map(toStory),
    sort,
  );
  const toggleSort = () =>
    void setSort(sort === "points" ? "comments" : "points");
  const toggleMatch = () =>
    void setMatch(match === "fuzzy" ? "exact" : "fuzzy");
  const cycleRange = () => void setRange(nextTimeRange(range));

  return (
    <List
      isLoading={isLoading || isRangeLoading || isSortLoading || isMatchLoading}
      throttle
      onSearchTextChange={setSearchText}
      searchBarPlaceholder="Search Hacker News…"
      searchBarAccessory={
        <List.Dropdown
          tooltip="Time range"
          value={range}
          onChange={(v) => void setRange(v as TimeRange)}
        >
          {TIME_RANGE_ORDER.map((value) => (
            <List.Dropdown.Item
              key={value}
              title={TIME_RANGE_TITLES[value]}
              value={value}
            />
          ))}
        </List.Dropdown>
      }
    >
      <List.Section
        title={`Sorted by ${sort === "points" ? "points" : "comments"}${
          match === "exact" ? " · exact match" : ""
        }`}
      >
        {stories.map((story) => (
          <StoryItem
            key={story.id}
            story={story}
            sort={sort}
            onToggleSort={toggleSort}
            range={range}
            onCycleRange={cycleRange}
            match={match}
            onToggleMatch={toggleMatch}
          />
        ))}
      </List.Section>
    </List>
  );
}

function StoryItem({
  story,
  sort,
  onToggleSort,
  range,
  onCycleRange,
  match,
  onToggleMatch,
}: {
  story: Story;
  sort: SortMode;
  onToggleSort: () => void;
  range: TimeRange;
  onCycleRange: () => void;
  match: MatchMode;
  onToggleMatch: () => void;
}) {
  const hasArticle = story.articleUrl !== null;
  const primaryUrl = story.articleUrl ?? story.discussionUrl;
  const nextRangeTitle = TIME_RANGE_TITLES[nextTimeRange(range)];

  return (
    <List.Item
      title={story.title}
      accessories={[
        { icon: Icon.ArrowUp, text: String(story.points), tooltip: "Points" },
        {
          icon: Icon.SpeechBubble,
          text: String(story.comments),
          tooltip: "Comments",
        },
        { icon: Icon.Person, text: story.author, tooltip: "Author" },
        { date: new Date(story.createdAt * 1000), tooltip: "Posted" },
      ]}
      actions={
        <ActionPanel>
          <Action.OpenInBrowser
            title={hasArticle ? "Open Article" : "Open Discussion"}
            url={primaryUrl}
          />
          {/* Second action gets Raycast's built-in Cmd+Enter (SecondaryAction). */}
          <Action.OpenInBrowser
            title="Open HN Discussion"
            icon={Icon.SpeechBubble}
            url={story.discussionUrl}
          />
          <Action
            title="Open Article and Comments"
            icon={Icon.AppWindowGrid2x2}
            shortcut={{ modifiers: ["cmd", "shift"], key: "return" }}
            onAction={async () => {
              await open(primaryUrl);
              // Ask HN and the like have no separate article; avoid a dup tab.
              if (hasArticle) {
                await open(story.discussionUrl);
              }
            }}
          />
          <Action.CopyToClipboard
            title="Copy Link"
            content={primaryUrl}
            shortcut={Keyboard.Shortcut.Common.Copy}
          />
          <Action
            title={`Sort by ${sort === "points" ? "Comments" : "Points"}`}
            icon={Icon.Switch}
            onAction={onToggleSort}
            shortcut={Keyboard.Shortcut.Common.Save}
          />
          <Action
            title={`Time Range: ${nextRangeTitle}`}
            icon={Icon.Clock}
            onAction={onCycleRange}
            shortcut={{ modifiers: ["cmd"], key: "t" }}
          />
          <Action
            title={match === "fuzzy" ? "Use Exact Match" : "Use Fuzzy Match"}
            icon={Icon.MagnifyingGlass}
            onAction={onToggleMatch}
            shortcut={Keyboard.Shortcut.Common.Edit}
          />
        </ActionPanel>
      }
    />
  );
}
