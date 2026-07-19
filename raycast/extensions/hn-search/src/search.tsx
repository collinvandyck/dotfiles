import { useState } from "react";
import { Action, ActionPanel, Icon, List, Keyboard } from "@raycast/api";
import { useFetch } from "@raycast/utils";
import {
  buildSearchURL,
  sortStories,
  toStory,
  type AlgoliaHit,
  type SortMode,
  type Story,
  type TimeRange,
} from "./hn";

interface SearchResponse {
  hits: AlgoliaHit[];
}

const TIME_RANGES: { value: TimeRange; title: string }[] = [
  { value: "24h", title: "Last 24 Hours" },
  { value: "week", title: "Past Week" },
  { value: "month", title: "Past Month" },
  { value: "year", title: "Past Year" },
  { value: "all", title: "All Time" },
];

export default function Command() {
  const [searchText, setSearchText] = useState("");
  const [range, setRange] = useState<TimeRange>("week");
  const [sort, setSort] = useState<SortMode>("points");
  // Fixed at mount so keystrokes don't churn the time window (and the fetch URL).
  const [nowSeconds] = useState(() => Math.floor(Date.now() / 1000));

  const { data, isLoading } = useFetch<SearchResponse>(
    buildSearchURL({ query: searchText, range, nowSeconds }),
    {
      keepPreviousData: true,
      failureToastOptions: { title: "Could not reach Hacker News" },
    },
  );

  const stories = sortStories((data?.hits ?? []).map(toStory), sort);
  const toggleSort = () =>
    setSort((s) => (s === "points" ? "comments" : "points"));
  const cycleRange = () =>
    setRange((r) => {
      const i = TIME_RANGES.findIndex((t) => t.value === r);
      return TIME_RANGES[(i + 1) % TIME_RANGES.length].value;
    });

  return (
    <List
      isLoading={isLoading}
      throttle
      onSearchTextChange={setSearchText}
      searchBarPlaceholder="Search Hacker News…"
      searchBarAccessory={
        <List.Dropdown
          tooltip="Time range"
          value={range}
          onChange={(v) => setRange(v as TimeRange)}
        >
          {TIME_RANGES.map((r) => (
            <List.Dropdown.Item key={r.value} title={r.title} value={r.value} />
          ))}
        </List.Dropdown>
      }
    >
      <List.Section
        title={`Sorted by ${sort === "points" ? "points" : "comments"}`}
      >
        {stories.map((story) => (
          <StoryItem
            key={story.id}
            story={story}
            sort={sort}
            onToggleSort={toggleSort}
            range={range}
            onCycleRange={cycleRange}
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
}: {
  story: Story;
  sort: SortMode;
  onToggleSort: () => void;
  range: TimeRange;
  onCycleRange: () => void;
}) {
  const hasArticle = story.articleUrl !== null;
  const primaryUrl = story.articleUrl ?? story.discussionUrl;
  const nextRange =
    TIME_RANGES[
      (TIME_RANGES.findIndex((t) => t.value === range) + 1) % TIME_RANGES.length
    ];

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
            title={`Time Range: ${nextRange.title}`}
            icon={Icon.Clock}
            onAction={onCycleRange}
            shortcut={{ modifiers: ["cmd"], key: "t" }}
          />
        </ActionPanel>
      }
    />
  );
}
