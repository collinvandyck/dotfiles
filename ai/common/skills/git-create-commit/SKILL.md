---
name: git-create-commit
description: Used when creating a git commit
---

# Overview

Create a commit written in Collin's voice. The description should be concise and have high S:N ratio. The commit should detail the change made, and why. The level of detail should be commensurate with the complexity of the change.

# Style

- Imperative mood. Often ends with a period, sometimes not — match gut feel.
- Optional topic prefix with a colon when the area is narrower than the repo: `saa: Instrument size of closed SAAs.`, `replay e2e: add remote driver for cell-based "gameday"`, `admintools: add vis-admin/verifier command.`, `wal-admin/replay: Driver abstraction and integration test.`
- No emoji.

Examples from real merged PRs:

- `Fix workflow TS standby verification logic.`
- `Speed up incremental CDS builds.`
- `Remove flaky SAA TS tests.`
- `Formalize and test SAA retention fallback chain`
- `Close walker incremental update (IU) iterator after use.`
- `replay: refactor waladmin package ahead of replay code`
- `Refactor remaining integration tests to CDS persistence layer 👹`

# Voice

- Passive style. "The mismatch check was moved into the loop". Avoid 'I/we' first person language.
- Conversational and direct.
- Forward-reference follow-up work when relevant ("Another branch exists which will...", "Will follow up with a PR that...").

# Links and References

Include these freely when they exist:

- Jira: `https://temporalio.atlassian.net/browse/CDS-XXXX` (often right under "What changed?" or as `Fixes <url>`)
- Slack: `[slack discussion](https://temporaltechnologies.slack.com/archives/...)` or `see: [slack discussion](...)` or `nb: [slack discussion](...)`
- Related PRs: bare `#1234` refs, often in a `### Related PRs:` list for stacks

# Anti-Patterns (don't do these)

- Don't use `**bold**` to lead every bullet or section. It reads as generated.
- Don't produce a bulleted list of changed files with line numbers. Describe the change, not the diff.
- Don't write a "Summary" that restates the title in more words.
- Don't invent sections the template doesn't need — a one-line Why under `### Why?` is fine.
- Don't list trivial test scenarios exhaustively. "Unit tests pass" or a short bulleted test plan is enough unless the tests themselves are the point of the PR.
- Don't turn "How did you test it?" into a recipe. A few bullets or a paragraph is plenty.

# Context

$ARGUMENTS

