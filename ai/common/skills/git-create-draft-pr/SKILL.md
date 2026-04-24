---
name: git-create-draft-pr
description: Used when creating a draft PR.
---

# Overview

Create a draft PR written in Collin's voice. Use the repo's PR template if one exists.

The description should guide a reviewer with a surface-level understanding of the area. Lead with what/why, then how. For complex changes, add code snippets, mermaid, or ASCII diagrams — but only when they actually help. Don't pad.

# Title Style

- Imperative mood. Often ends with a period, sometimes not — match gut feel.
- Optional topic prefix with a colon when the area is narrower than the repo: `saa: Instrument size of closed SAAs.`, `replay e2e: add remote driver for cell-based "gameday"`, `admintools: add vis-admin/verifier command.`, `wal-admin/replay: Driver abstraction and integration test.`
- Keep it short. Title describes the change, not the motivation.
- No emoji unless the PR truly warrants one (🔪 for a big deletion, 👹 for a large/gnarly refactor). Default: none.

Examples from real merged PRs:

- `Fix workflow TS standby verification logic.`
- `Speed up incremental CDS builds.`
- `Remove flaky SAA TS tests.`
- `Formalize and test SAA retention fallback chain`
- `Close walker incremental update (IU) iterator after use.`
- `replay: refactor waladmin package ahead of replay code`
- `Refactor remaining integration tests to CDS persistence layer 👹`

# Description Structure

## Use the template headers

When the repo's PR template has `### What changed?` / `### Why?` / `### How did you test it?`, keep those exact headers. Preserve the checkbox list:

```
- [ ] Unit Tests
- [ ] Staging
- [ ] End to End Tests
```

Tick the boxes that actually apply. Don't invent categories.

## Scale the description to the change

**Small PRs** (a few files, narrow fix): keep it small. A one-liner in "Why?" is fine.

> ### Why?
>
> It's good to have fast things.

> ### Why?
>
> Don't want to block builds.

> ### Why?
>
> Flaky tests are bad

**Medium PRs**: brief paragraphs under each header. Inline code for the key method/type names. Call out the one or two non-obvious things.

**Large PRs**: switch to `## What` / `## How` / `## Test plan`, and add freeform sections as needed:

- `## Summary` — one paragraph up top
- `## Roadmap` — when this PR is one step in a sequence; list the steps with `(YOU ARE HERE)` on the current one
- `## Background` — if reviewers need context they won't have
- `## How to read this PR` — when commit order matters; a table mapping commit prefixes to what to expect is great
- `## A stopping point` / `## Not Done` — honest about what's deferred and why
- `## Alternatives` / `## Alternatives considered` — tradeoffs you ruled out
- `## Reviewing` — direct note to reviewers (e.g., "easier to review in commit order")

For multi-commit PRs structured for commit-order review, say so explicitly.

# Voice

- First person. "I did X because Y."
- Conversational and direct. Dry humor is welcome when it fits — don't force it.
- Admit tradeoffs openly: "This is a shortcut.", "I had to stop working on this.", "It's good enough for now.", "I need to stop working on this."
- Name the footgun when there is one. Explain *why* something is safe or unsafe, not just that it is.
- Forward-reference follow-up work when relevant ("I've got another branch which will...", "We'll follow up with a PR that...").

# Links and References

Include these freely when they exist:

- Jira: `https://temporalio.atlassian.net/browse/CDS-XXXX` (often right under "What changed?" or as `Fixes <url>`)
- Slack: `[slack discussion](https://temporaltechnologies.slack.com/archives/...)` or `see: [slack discussion](...)` or `nb: [slack discussion](...)`
- Related PRs: bare `#1234` refs, often in a `### Related PRs:` list for stacks

# Formatting Conventions

- Headers: `###` inside the PR template; `##` for larger PRs that step outside it.
- Inline `code` for identifiers (methods, types, flags, files).
- Fenced code blocks for snippets, always with a language (`go`, `sh`, `proto`, `yaml`, `mermaid`, `protobuf`, `diff`).
- Tables are good for before/after measurements and flag references.
- **Bold** used sparingly as an inline label (`**Before:**`, `**After:**`, `**Why this is safe:**`, `**Workflows**` / `**SAAs**` when contrasting two things). Never as scattered emphasis or decoration.
- Diagrams (mermaid or ASCII) only when they illustrate something a paragraph can't.

# Anti-Patterns (don't do these)

- Don't use `**bold**` to lead every bullet or section. It reads as generated.
- Don't produce a bulleted list of changed files with line numbers. Describe the change, not the diff.
- Don't write a "Summary" that restates the title in more words.
- Don't invent sections the template doesn't need — a one-line Why under `### Why?` is fine.
- Don't list trivial test scenarios exhaustively. "Unit tests pass" or a short bulleted test plan is enough unless the tests themselves are the point of the PR.
- Don't add emojis as decoration. The occasional 🔪 / 👹 is a deliberate signal, not a sparkle.
- Don't turn "How did you test it?" into a recipe. A few bullets or a paragraph is plenty.

# Before Creating the PR

- Check for a PR template and use it.
- If there's a Jira for the work, include it.
- If the PR is part of a stack or follows related PRs, link them.
- Always create as a draft unless explicitly told otherwise.

# Context

$ARGUMENTS
