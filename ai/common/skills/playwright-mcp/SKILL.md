---
name: playwright-mcp
description: Use when verifying or debugging behavior in a browser — single-file HTML, web apps, interactive UI — that requires DOM inspection, click simulation, or evaluating JS in page context.
allowed-tools: Bash(pkill:*)
---

# Playwright MCP

The `@playwright/mcp` server exposes browser automation as native tools (`mcp__playwright__browser_*`). Reach for them BEFORE writing a Playwright/Puppeteer Node script — the script is only worth it for repeatable test suites kept under version control.

## Tool primitives

Schemas are deferred; load via `ToolSearch` first.

- `browser_navigate` — open a URL.
- `browser_snapshot` — accessibility tree with `ref=eN` IDs you can target.
- `browser_click` — click an element by `ref` from a snapshot.
- `browser_evaluate` — arbitrary JS in page context. The escape hatch.
- `browser_console_messages` — collected console errors/warnings.
- `browser_take_screenshot` — when pixels matter.
- `browser_close` — close the tab.

Also available: `browser_type`, `browser_press_key`, `browser_fill_form`, `browser_hover`, `browser_resize`, `browser_tabs`, `browser_network_requests`, `browser_wait_for`.

## Local files need an HTTP server

`file://` URLs are blocked. Serve the directory first:

```bash
cd /path/to/dir && python3 -m http.server 8765 &
```

Then navigate to `http://localhost:8765/<file>.html`.

## Cleanup

When the session is done, kill the HTTP server you started — it does not exit on its own and will linger across sessions if left running:

```bash
pkill -f "http.server 8765"
```

Match the port string you started with. This `pkill` invocation is allow-listed for this skill.

## Typical loop

1. Start HTTP server if testing a local file.
2. `browser_navigate` to URL.
3. To start fresh: `browser_evaluate(() => localStorage.clear())` then re-navigate.
4. `browser_snapshot` → grab refs for elements you need.
5. Click / type / interact via the refs.
6. `browser_evaluate` to read state and assert.
7. Repeat.
8. `browser_close` and kill the server when done.

## Tips

- A snapshot is cheaper than a screenshot for most checks.
- `browser_evaluate` returns JSON-serializable values — use it to pull structured state, not just trigger effects.
