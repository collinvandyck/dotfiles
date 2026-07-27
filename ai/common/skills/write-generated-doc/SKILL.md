---
name: write-generated-doc
description: Writes a generated doc into a common location dependent on type
disable-model-invocation: false
user-invocable: true
allowed-tools: Write(~/code/notes/tech/ai/gen/**), Bash(open:*), Skill(notion), Skill(writing-mermaid-diagrams), mcp__notion__notion-fetch, mcp__notion__notion-query-data-sources, mcp__notion__notion-create-pages, mcp__notion__notion-update-page
---

Generated docs land in one of two systems of record. Resolve the destination
from the routing table before you start writing: it decides whether you produce
a file or a database row, and a row needs properties a file doesn't.

# Routing

| Kind | Destination |
|------|-------------|
| Review of a GitHub PR (`local-pr-review`) | Notion — the **PR Reviews** database |
| Review of a local or uncommitted diff (`local-review`) | Obsidian — `local-reviews/` |
| Everything else | Obsidian — `~/code/notes/tech/ai/gen/<folder>/` |

Work docs are migrating to Notion, but only PR reviews have a home there so
far. Every other kind stays in Obsidian until its Notion structure exists. When
a kind moves, add a row to this table — don't teach the calling skill about
Notion.

# Notion: PR reviews

Read the `notion` skill before writing any page content. It covers real
newlines (literal `\n` escapes flatten the whole page into one paragraph),
mermaid, and opening pages in the desktop app.

- Database page: `https://app.notion.com/p/temporalio/PR-Reviews-3aa8fc567738808194cef429fcd88628`
- Data source: `collection://3aa8fc56-7738-80a2-ac0d-000b069eab21`

## Properties

| Property | Value |
|----------|-------|
| `Title` | The full PR URL, e.g. `https://github.com/temporalio/saas-temporal/pull/8159` |
| `PR Title` | The PR's own title, verbatim |
| `GH Author` | The author's GitHub handle, no leading `@` |
| `Status` | Leave unset. Collin owns this field — it tracks his review progress, not yours. |

The page body is the full review: the same document you would have written to
Obsidian, not a summary and not a link to one.

## Check for an existing row first

A filename made Obsidian idempotent. Notion is not — re-reviewing a PR will
happily create a second row. Query before you create:

```sql
SELECT url, "Title" FROM "collection://3aa8fc56-7738-80a2-ac0d-000b069eab21" WHERE "Title" = ?
```

Bind the PR URL as the parameter. If the query returns a row, replace that
page's content. If it returns nothing, create a new page in the data source.

## Opening the page

Convert the returned `https://` URL to `notion://` so it routes to the desktop
app rather than the browser, and use `open -g` to leave focus where the user
left it:

```bash
open -g "notion://app.notion.com/p/<page-id>"
```

# Obsidian: everything else

The `~/code/notes/tech/ai/gen/` folder is the Obsidian vault location where
generated documents are collected over time. (`~/code/notes` is a symlink to
the iCloud Obsidian vault.)

```shell
tree ~/code/notes/tech/ai/gen -L 1
~/code/notes/tech/ai/gen
├── cover-letters
├── implementations
├── investigations
├── local-reviews
├── perf
├── performance-reviews
├── plans
├── poetry
├── prs
├── reviews
├── talks
├── walkthroughs
└── wikis
```

Place the doc in the appropriate folder. If there is no such folder, create it
using the same style as the others.

Example:

```markdown
Use write-generated-doc to save the [cover letter|local review| etc]
```

Cover letters are written into `~/code/notes/tech/ai/gen/cover-letters`.
Plans are written into `~/code/notes/tech/ai/gen/plans`.
And so on.

The file name should be formatted as `$kind-$topic.md`.
Use kebab-case for the filename.
The kind should be `cover-letter`, `pr-$num`, `walkthrough`, etc.

PR files should include the PR number in the filename.
For example, a local review might look like: `pr-6202-review-refactor-tests.md`.

## Opening the doc

After writing the file, always open it in Obsidian using the deep link. The
vault is named `notes` and the `file` parameter is the path relative to the
vault root — drop the `~/code/notes/` prefix.

Use `open -g` so Obsidian navigates to the note in the background without
stealing focus from the user's current window:

```bash
open -g "obsidian://open?vault=notes&file=tech/ai/gen/<type>/<filename-without-md>"
```

Example: a file written to `~/code/notes/tech/ai/gen/walkthroughs/walkthrough-foo.md`
is opened with:

```bash
open -g "obsidian://open?vault=notes&file=tech/ai/gen/walkthroughs/walkthrough-foo"
```

The `.md` extension can be omitted — Obsidian resolves it. Always wrap the URL
in double quotes so the shell doesn't misinterpret `&`. The `-g` flag keeps
Obsidian in the background (it's advisory — a cold start may still foreground
once, but an already-running Obsidian stays put).

# Formatting Conventions

These apply to both destinations.

- No hard line breaks inside a paragraph. Write each paragraph as a single unbroken line and let it wrap — GitHub renders manual newlines as `<br>`, which truncates the width and reads as generated. Blank lines between paragraphs are fine; this only applies to prose, not lists, tables, or code blocks.
- Headers: `###` inside the PR template; `##` for larger PRs that step outside it.
- Inline `code` for identifiers (methods, types, flags, files).
- Fenced code blocks for snippets, always with a language (`go`, `sh`, `proto`, `yaml`, `mermaid`, `protobuf`, `diff`).
- Tables are good for before/after measurements and flag references.
- **Bold** used sparingly as an inline label (`**Before:**`, `**After:**`, `**Why this is safe:**`, `**Workflows**` / `**SAAs**` when contrasting two things). Never as scattered emphasis or decoration.
- Diagrams only when they illustrate something a paragraph can't, and always mermaid — never ASCII art. Obsidian and Notion both render mermaid, so the format doesn't depend on where the doc lands. Read the `writing-mermaid-diagrams` skill before the first diagram line, not after it renders wrong.

# Context

$ARGUMENTS
