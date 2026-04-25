---
name: fastmod
description: Use when making many repetitive code edits across files — bulk rename, mass find-and-replace, codebase-wide substitution.
---

# fastmod

## Overview

`fastmod` performs regex-based find-and-replace across an entire codebase in a single command. Use it instead of editing files one at a time when 3 or more files need the same substitution.

## Quick Reference

```bash
# Basic: replace all matches, no prompts
fastmod --accept-all 'PATTERN' 'REPLACEMENT'

# Scope to file extensions
fastmod --accept-all --extensions rs,go 'old_fn' 'new_fn'

# Scope to a directory
fastmod --accept-all --dir src/ 'OldName' 'NewName'
```

Regex uses Rust regex syntax (no lookaheads). Use capture groups with `$1`, `$2`, etc.

## Example

Rename a function signature pattern across all Go files:

```bash
fastmod --accept-all --extensions go 'OldStructName' 'NewStructName'
```

## Common Mistakes

- **Forgetting `--accept-all`**: Without it, fastmod prompts interactively, which hangs in non-interactive shells.
- **Too-broad scope**: Always scope with `--extensions` or `--dir` to avoid modifying generated code, binaries, or vendored files.
- **Greedy regexes**: Use `(.+?)` (non-greedy) instead of `(.+)` when matching delimited content.
- **Not verifying first**: Inspect the diff afterward to catch unintended replacements.
