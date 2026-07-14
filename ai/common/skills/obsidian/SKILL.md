---
name: obsidian
description: Work with Collin's Obsidian vault at ~/code/notes — manage Tasks-plugin tasks (especially in the daily note), capture journal entries, search and recall across notes, and author/edit notes following the vault's conventions. Use when the user mentions Obsidian, the vault, daily notes, tasks (- [ ] / #task), wikilinks, or asks to find/append/create notes. Drives the live `obsidian` CLI against the running app.
---

# Obsidian Vault

This skill works with the Obsidian vault at `~/code/notes`. It drives the **live `obsidian` CLI** against the running app rather than editing markdown files directly, because the CLI resolves the daily note correctly, sees real plugin state, and routes writes through Obsidian — which auto-saves and auto-commits the same files (obsidian-git, ~5 min). Fighting that with raw edits causes conflicts.

## First: confirm the app is reachable

```sh
obsidian vault info=name        # prints "notes" when reachable
```

- **Reachable** → use the CLI for everything below.
- **Not reachable** (error / no output) → fall back to plain Read/Edit/Write on `~/code/notes`. Tell the user that Tasks/dataview queries won't evaluate in this mode.

**Dates**: always get today from `date +%F` at the moment you need it. Never reuse a date from earlier in the session — sessions outlive it.

## CLI quick reference

Conventions: `file=<name>` resolves like a wikilink (no extension); `path=<folder/note.md>` is exact; most commands default to the active file when neither is given. Quote values with spaces (`content="..."`); use `\n` and `\t` inside content. Run `obsidian help <command>` for the full flag list.

| Job | Command |
|-----|---------|
| Read a note | `obsidian read path=work/temporal/projects/vis.md` |
| Read today's daily note | `obsidian daily:read` |
| Daily note path | `obsidian daily:path` |
| Append to today's note | `obsidian daily:append content="..."` |
| Append to a note | `obsidian append path=foo.md content="..."` |
| Create a note | `obsidian create path=tech/foo.md content="..."` (add `template=<name>`) |
| List tasks | `obsidian tasks [todo|done] [path=…] [status="<char>"] [daily] [verbose] [format=json|tsv|csv]` |
| Update a task | `obsidian task ref=path:line [done|todo|toggle|status="<char>"]` |
| Search | `obsidian search query="text" [path=folder] [limit=N]` |
| Search w/ line context | `obsidian search:context query="text"` |
| Tags / one tag | `obsidian tags [counts] [sort=count]` · `obsidian tag name=vis verbose` |
| Backlinks | `obsidian backlinks file="Note"` |
| Set a property | `obsidian property:set name=status value=done path=foo.md` |
| List / insert template | `obsidian templates` · `obsidian template:insert name=go` |
| Run / list app commands | `obsidian command id=<id>` · `obsidian commands filter=<prefix>` |

`tasks todo` matches status `[ ]` only — in-progress (`[/]`) tasks need `status="/"`, not `todo`.

## Vault conventions

Follow these by default; they're the grain of the vault, not a straitjacket.

**Folders** (domain-first, restructured 2026-07): `daily/YYYY/` (daily notes), `work/temporal/{projects,runbooks,rcas,on-call}/` (the job), `tech/` (technical reference — languages, tools, infra), `life/{health,finance,home,banjo,games,divorce,jobsearch}/` (personal), `people/` (all person-notes), `archive/` (dormant / former-work), `_templates/`, `_attachments/`, `_meta/`. New tasks and captures go in the **freeform section of the daily note**, below the `---`; the Tasks queries sit above it.

**Frontmatter**: every non-daily note carries `type` (one of `project`/`reference`/`person`/`runbook`/`rca`/`meeting`/`note`) and `tags: [...]`; `project` notes also carry `status` (`active`/`done`/`dormant`). The folder supplies domain/area — don't duplicate it into frontmatter. The full spec lives in `_meta/conventions.md`, and the `_meta/` Bases dashboards (`Home`, `Now`, `Work`, `Tech`, `Life`, `People`) read these properties to build themselves.

**Tasks syntax** (Tasks plugin):

```
- [ ] #task #vis description ➕ 2026-06-16 📅 2026-06-16 ✅ 2026-06-16
```

Status characters: `[ ]` todo · `[/]` in-progress · `[x]` done · `[-]` cancelled. Emoji metadata: `➕` created · `📅` due · `✅` done. When **adding** a task, include `#task`, the relevant project tag, and `➕<today>`; add `📅<due>` when a due date is implied.

**Tags** — the dashboard-driving vocabulary to reach for (use others when they fit better): `#vis #next #life #ai #msts #banjo #flusher #replay #oncall #career #work #temporal`. `Tasks.md` is the at-a-glance dashboard that groups open/done tasks by these tags — read it for context, don't edit its queries.

**Markdown**: wikilinks `[[Note]]` and `[[Note#Heading|Display]]`, never `[](file.md)`. Obsidian Flavored Markdown is available — embeds `![[note]]` / `![[img.png|300]]`, callouts `> [!note]` / `> [!warning] Title` / `> [!faq]-` (collapsed), frontmatter properties, inline tags `#tag`, comments `%%hidden%%`, highlights `==text==`.

**Writing**: use Collin's voice per the global CLAUDE.md style — no artificial line breaks in prose, his style for prose and commit messages.

## Workflow recipes

### Add a task to today's note

```sh
today=$(date +%F)
obsidian daily:append content="- [ ] #task #vis wire up the reindex helper ➕ $today"
```

For a due date, append ` 📅 <due>`. To add a task to a project note instead, `obsidian append path=work/temporal/projects/vis.md content="..."`.

### Complete a task (with the ✅ date)

`obsidian task … done` flips `[ ]`→`[x]` but does **not** add the `✅` date — the date is the Tasks *plugin's* completion behavior, not a checkbox property, and the CLI does a raw character flip without running the plugin. The daily "Completed" query (`done on <date>`) and the `Tasks.md` dashboard both key off that date, so stamp it explicitly:

1. Locate the exact line: `obsidian tasks path=daily/2026/2026-06-16.md verbose format=tsv` (gives text + line number).
2. Rewrite that one line to `[x]` with ` ✅<today>` appended — use the Edit tool for a precise single-line replacement (a targeted edit is low-risk; Obsidian reloads the external change and obsidian-git commits it).

Don't rely on the Tasks plugin's `toggle-done` command via the CLI — it acts on the editor cursor and no-ops headless.

### Change status / reschedule

Status flip only (no date semantics): `obsidian task ref=path:line status="/"` (in-progress) or `todo`. To reschedule, edit the `📅` date on the line (Edit tool for precision).

### Capture a journal entry or decision

```sh
obsidian daily:append content="\nHit a wall on the async write batching — parts count spikes under load. Parking until M2 ships."
```

### Search & recall

- Find notes: `obsidian search query="tiered storage" limit=10`.
- With context lines: `obsidian search:context query="reindex"`.
- "What did I work on recently": `obsidian read path=daily/2026/2026-06-16.md` (and prior days), or list tasks done in a range with `obsidian tasks done`.
- Explore connections: `obsidian backlinks file="ms tiered storage"`, `obsidian tag name=vis verbose`.

### Author a new note

```sh
obsidian create path=work/temporal/projects/foo/overview.md content="# Foo\n\nLinks to [[ms tiered storage]]." open
```

Use `template=<name>` to start from a template (`obsidian templates` lists them). Set frontmatter with `obsidian property:set name=tag value=temporal path=...`.

## Safety

- Prefer the CLI over raw edits while the app is live. The one sanctioned exception is a **targeted single-line Edit** to stamp a task's `✅`/`📅` date, which the CLI can't do mid-line.
- Confirm destructive ops before running: `delete` (use trash, not `permanent`, unless asked), `move`, and `create … overwrite`.
- The vault auto-commits on a timer — don't fight git, and surface anything unexpected rather than silently overwriting it.
