---
name: notion
description: Conventions for working with Notion — reading, creating, or updating Notion pages and databases, opening Notion links/URLs, or driving the Notion MCP tools. Use whenever the user mentions Notion, pastes a Notion link (app.notion.com / notion.so), or you are about to open, create, or update a Notion page.
---

# Notion

Practical conventions for working with Notion on this machine: opening pages in the desktop app, writing page content, and authoring diagrams. More Notion workflows will be added over time.

## Opening Notion links

Always open Notion pages in the Notion desktop app, not the browser or the default system handler.

- **Primary method:** convert the URL scheme from `https://` to `notion://` and open it. The `notion://` scheme routes to the desktop app.
  - `https://app.notion.com/p/<id>` becomes `open "notion://app.notion.com/p/<id>"`
  - `https://www.notion.so/<id>` becomes `open "notion://www.notion.so/<id>"`
- **Fallback** (if `notion://` does not route to the app): force the https URL open in Notion specifically with `open -a Notion "<https-url>"`.
- **Do NOT** use plain `open "https://..."` for Notion links — that goes to the default browser.

## Writing page content

When writing Notion page content, use **real newlines** — never literal `\n` escape sequences. This applies to the `content` field of `notion-create-pages`, and the `new_str` / `content` / `content_updates` fields of `notion-update-page` (including `insert_content`).

- Separate every block (headings, paragraphs, list items, dividers `---`, code fences) with actual line breaks. Pass multi-line strings, not strings with embedded `\n`.
- Fenced code blocks and ```mermaid diagrams especially need real newlines — Notion parses them line by line.
- If you pass literal backslash-n sequences, Notion stores them verbatim: the whole block collapses into one run of text with visible `\n`/`nn` characters, and headings, bullets, dividers, and code fences all flatten into a single paragraph.
  - Observed in practice: an `insert_content` call using `\n` escapes flattened an entire multi-section addendum (with a mermaid diagram) into one unreadable paragraph.
- **Fixing an already-mangled block:** issue a surgical `update_content` that matches the broken text and replaces it with a properly newline-formatted version.

## Diagrams

**Notion renders mermaid. Always use mermaid for diagrams on a Notion page — never ASCII art in a fenced code block.**

This holds even when another skill asks for ASCII diagrams. The destination decides the format: a skill saying "diagrams should be ascii-art inside fenced code blocks" is describing a terminal or plain-text target. When the artifact lands in Notion, mermaid wins. (Observed: a PR review authored with ASCII diagrams had to be converted afterward.)

- **Read the `writing-mermaid-diagrams` skill before writing the first diagram line**, not after it renders wrong. It covers the two characters that silently break the parser inside note and label text (`;` and a literal `->`) and the fact that line breaks need `<br/>`, not `\n`.
- **Tag the fence `mermaid` explicitly.** Notion guesses a language for untagged code blocks and guesses badly — ASCII diagrams land as ```` ```javascript ````, which of course doesn't render. Same trap applies if you paste a diagram without the language.
- **No `style` / rgb / theme directives.** Let Notion's default theme handle it, so the diagram reads in both light and dark mode.
- Real newlines, per the section above. A mermaid block with `\n` escapes flattens into one unreadable paragraph.

### Picking a form

- **`sequenceDiagram`** for anything about ordering, interleaving, or a race between actors. Use `->>+` / `-->>-` activation markers when a lock or resource is held across steps — the activation bar shows the hold window, which is usually the whole point.
- **`flowchart TD`** for branching paths that reconverge, decision trees, and state transitions.

### Verifying before you publish

`mermaid-cli` renders headlessly and fails loudly on syntax errors, so a parse check is cheap:

```sh
npx -y @mermaid-js/mermaid-cli@latest -i diagram.mmd -o diagram.svg
```

Add `-o diagram.png -s 2` and read the PNG back to check that it's actually legible, not merely valid. Worth doing for anything non-trivial — a diagram that parses can still lay out badly.

### Converting an existing page

Match the whole fenced block, including both fence lines, in an `update_content` `old_str` — the wrong language tag is part of what you're replacing:

````
old_str:  the opening ```javascript fence, the ASCII art, the closing fence
new_str:  the opening ```mermaid fence, the diagram, the closing fence
````

Fetch the page first and copy the old block verbatim out of the response — Notion may have re-indented what you originally wrote, so don't reconstruct it from memory. Both strings still need real newlines, not `\n` escapes.
