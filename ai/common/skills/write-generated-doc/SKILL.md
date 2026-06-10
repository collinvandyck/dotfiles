---
name: write-generated-doc
description: Writes a generated doc into a common location dependent on type
disable-model-invocation: false
user-invocable: true
allowed-tools: Write(~/code/notes/ai/gen/**), Bash(open:*)
---

The `~/code/notes/ai/gen/` folder is the Obsidian vault location where
generated documents are collected over time. (`~/code/notes` is a symlink to
the iCloud Obsidian vault.)

```shell
tree ~/code/notes/ai/gen -L 1
~/code/notes/ai/gen
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

When asked to write a generated doc, place it in the appropriate folder.
If there is no such folder, create it using the same style as the others.

Example:

```markdown
Use write-generated-doc to save the [cover letter|local review| etc]
```

Cover letters are written into `~/code/notes/ai/gen/cover-letters`.
Plans are written into `~/code/notes/ai/gen/plans`.
And so on.

The file name should be formatted as `$kind-$topic.md`.
Use kebab-case for the filename.
The kind should be `cover-letter`, `pr-$num`, `walkthrough`, etc.

PR files should include the PR number in the filename.
For example, a PR review might look like: `pr-6202-review-refactor-tests.md`.

# Formatting Conventions

- No hard line breaks inside a paragraph. Write each paragraph as a single unbroken line and let it wrap — GitHub renders manual newlines as `<br>`, which truncates the width and reads as generated. Blank lines between paragraphs are fine; this only applies to prose, not lists, tables, or code blocks.
- Headers: `###` inside the PR template; `##` for larger PRs that step outside it.
- Inline `code` for identifiers (methods, types, flags, files).
- Fenced code blocks for snippets, always with a language (`go`, `sh`, `proto`, `yaml`, `mermaid`, `protobuf`, `diff`).
- Tables are good for before/after measurements and flag references.
- **Bold** used sparingly as an inline label (`**Before:**`, `**After:**`, `**Why this is safe:**`, `**Workflows**` / `**SAAs**` when contrasting two things). Never as scattered emphasis or decoration.
- Diagrams (mermaid or ASCII) only when they illustrate something a paragraph can't.


## Opening the doc

After writing the file, always open it in Obsidian using the deep link. The
vault is named `notes` and the `file` parameter is the path relative to the
vault root — drop the `~/code/notes/` prefix.

```bash
open "obsidian://open?vault=notes&file=ai/gen/<type>/<filename-without-md>"
```

Example: a file written to `~/code/notes/ai/gen/walkthroughs/walkthrough-foo.md`
is opened with:

```bash
open "obsidian://open?vault=notes&file=ai/gen/walkthroughs/walkthrough-foo"
```

The `.md` extension can be omitted — Obsidian resolves it. Always wrap the URL
in double quotes so the shell doesn't misinterpret `&`.

# Context

$ARGUMENTS
