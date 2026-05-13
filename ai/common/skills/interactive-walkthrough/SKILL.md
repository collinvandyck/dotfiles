---
name: interactive-walkthrough
description: Generate a self-contained interactive HTML walkthrough of code
allowed-tools: Bash, Read, Write, WebFetch
disable-model-invocation: true
---

# Overview

Your goal is to produce a self-contained, richly-styled HTML walkthrough of the specified code. The output is one HTML file that opens in a browser with no external dependencies — no CDN CSS, no remote fonts, no network calls. The user is not familiar with this area of the code and wants a guided, conversational, but professional walkthrough. Same expectations as the `code-walkthrough` skill, but rendered as HTML rather than markdown.

If `$ARGUMENTS` includes a path to an existing markdown walkthrough, use it as the source of truth — preserve its structure, steps, and gotchas. If not, do your own walkthrough reasoning first (the way `code-walkthrough` would), then render it.

When done, write the file and open it in the browser with `open $path`.

# Visual scaffolding

Read `~/.claude/skills/interactive-walkthrough/skeleton.html` before writing. It is the chrome: dark theme, CSS variables, typography, syntax-highlighted code blocks, ASCII-diagram styling, gotcha/note blockquotes, collapsible `<details class="dive">` deep-dives, TOC, hero header, footer, and minimal Go + shell syntax highlighters. Use it as your starting point. Extend the CSS for content-specific needs, but do not replace the visual language.

# Interactivity

Interactivity is optional. A well-styled, syntax-highlighted, collapsible-organized static page is a valid and often correct output. Do NOT add interactive widgets to make the page feel "interactive."

Build something tailored only when the walkthrough's central concept has a mechanic that genuinely rewards hands-on exploration. Examples that fit: concurrency gates, queue draining, signal-driven state changes, batch admission, state machines, retry/backoff, race windows. Examples that do not: the layout of a struct, the shape of a file tree, a one-shot procedure, a list of fields, a config schema.

If you build something interactive, hand-roll it for this specific mechanic. Don't reach for a generic visualization template. A small, faithful model of the actual behavior is what makes it good.

# Content guidelines

- Identify the central mechanic or invariant of the walkthrough early. Let everything else orbit it.
- Use analogies and ASCII diagrams when they help. Diagrams go in `<pre class="ascii">`.
- Show relevant code in syntax-highlighted `<pre><code class="go">` (or `sh`) blocks.
- Step-by-step structure: number sections with `<span class="stepnum">N</span>` inside the `<h2>`.
- Call out common mistakes, surprising behavior, and subtle invariants in `<blockquote class="gotcha">` or `<blockquote class="note">`.
- Conversational tone; use multiple analogies for complex concepts.
- Use `<details class="dive">` for asides that would interrupt the main flow.
- No soft breaks in the generated output. Long paragraphs are fine; manual line breaks inside paragraphs are not.

# Output location

Write to `~/code/notes/ai/gen/walkthroughs/walkthrough-$topic.html` (kebab-case, matching the convention used by `write-generated-doc` for markdown walkthroughs). If a file with that name exists, append `-YYYY-mm-dd`.

Open the resulting file with `open "$path"` — this launches the default browser. Do not use the Obsidian deep-link (Obsidian won't render HTML).

If you need additional information from the user, ask before generating.

# User Context

$ARGUMENTS
