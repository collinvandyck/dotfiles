---
name: notion
description: Conventions for working with Notion — reading, creating, or updating Notion pages and databases, opening Notion links/URLs, or driving the Notion MCP tools. Use whenever the user mentions Notion, pastes a Notion link (app.notion.com / notion.so), or you are about to open, create, or update a Notion page.
---

# Notion

Practical conventions for working with Notion on this machine. For now this covers opening pages in the desktop app; more Notion workflows and conventions will be added over time.

## Opening Notion links

Always open Notion pages in the Notion desktop app, not the browser or the default system handler.

- **Primary method:** convert the URL scheme from `https://` to `notion://` and open it. The `notion://` scheme routes to the desktop app.
  - `https://app.notion.com/p/<id>` becomes `open "notion://app.notion.com/p/<id>"`
  - `https://www.notion.so/<id>` becomes `open "notion://www.notion.so/<id>"`
- **Fallback** (if `notion://` does not route to the app): force the https URL open in Notion specifically with `open -a Notion "<https-url>"`.
- **Do NOT** use plain `open "https://..."` for Notion links — that goes to the default browser.
