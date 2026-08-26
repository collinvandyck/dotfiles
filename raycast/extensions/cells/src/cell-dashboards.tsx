import { useMemo, useState } from "react";
import {
  Action,
  ActionPanel,
  Icon,
  Keyboard,
  List,
  Toast,
  closeMainWindow,
  open,
  showToast,
} from "@raycast/api";

import { matchesFilter, parseQuery } from "./cell";
import { DASHBOARDS, type Dashboard } from "./dashboards";
import { MissingEnvError, loadEnv, type Env } from "./env";
import { readLastCell, writeLastCell } from "./storage";

// Icons are a display concern, so they live here rather than in the catalog,
// which stays free of @raycast/api.
const ICONS: Record<string, Icon> = {
  obs: Icon.AppWindowGrid2x2,
  alerts: Icon.Bell,
  "persistence-errors": Icon.ExclamationMark,
  "error-logs": Icon.Text,
  workflows: Icon.Bolt,
};

export default function Command() {
  // Seeded with the last cell and a trailing space, so the cursor lands where a
  // filter would go and the common case is zero typing.
  const [searchText, setSearchText] = useState(() => {
    const last = readLastCell();
    return last === "" ? "" : `${last} `;
  });
  const env = useMemo(() => {
    try {
      return { value: loadEnv() };
    } catch (error) {
      return { error: error as Error };
    }
  }, []);

  const { cell, filter } = parseQuery(searchText);
  const visible = DASHBOARDS.filter((d) =>
    matchesFilter(filter, d.title, d.subtitle),
  );

  const openDashboard = async (dashboard: Dashboard) => {
    if (!env.value) {
      return;
    }
    if (cell === "") {
      await showToast({
        style: Toast.Style.Failure,
        title: "Type a cell first",
      });
      return;
    }
    writeLastCell(cell);
    await closeMainWindow();
    for (const url of dashboard.urls(cell, env.value)) {
      await open(url);
    }
  };

  if (env.error) {
    const missing = env.error instanceof MissingEnvError;
    return (
      <List>
        <List.EmptyView
          icon={Icon.Warning}
          title={missing ? "Missing configuration" : "Could not read ~/.env"}
          description={env.error.message}
        />
      </List>
    );
  }

  return (
    <List
      // The search field is the cell input, not a filter over the list, so the
      // filtering below is ours to do.
      filtering={false}
      searchText={searchText}
      onSearchTextChange={setSearchText}
      searchBarPlaceholder="cell, then a filter — e.g. aw021 vis"
    >
      <List.EmptyView
        icon={Icon.MagnifyingGlass}
        title={cell === "" ? "Type a cell" : `No dashboard matches “${filter}”`}
      />
      <List.Section title={cell === "" ? "Dashboards" : `Cell ${cell}`}>
        {visible.map((dashboard) => (
          <DashboardItem
            key={dashboard.id}
            dashboard={dashboard}
            cell={cell}
            env={env.value}
            onOpen={() => openDashboard(dashboard)}
          />
        ))}
      </List.Section>
    </List>
  );
}

function DashboardItem({
  dashboard,
  cell,
  env,
  onOpen,
}: {
  dashboard: Dashboard;
  cell: string;
  env: Env | undefined;
  onOpen: () => void;
}) {
  const urls = cell !== "" && env ? dashboard.urls(cell, env) : [];
  const accessories =
    urls.length > 1 ? [{ tag: `${urls.length} tabs`, icon: Icon.Window }] : [];

  return (
    <List.Item
      icon={ICONS[dashboard.id] ?? Icon.LineChart}
      title={dashboard.title}
      subtitle={dashboard.subtitle}
      accessories={accessories}
      actions={
        <ActionPanel>
          <Action title="Open" icon={Icon.Globe} onAction={onOpen} />
          {urls.length > 0 && (
            <Action.CopyToClipboard
              title="Copy Link"
              content={urls[0]}
              shortcut={Keyboard.Shortcut.Common.Copy}
            />
          )}
        </ActionPanel>
      }
    />
  );
}
