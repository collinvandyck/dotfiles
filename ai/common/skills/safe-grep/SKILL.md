---
name: safe-grep
description: Use instead of Search when searching file for a pattern with special characters like pipes (|), quotes("), or brackets([||)
allowed-tools: Bash(*/safe-grep *)
---

# Safe Grep

Wraps `rg` with regex validation for patterns that security hooks reject.

## Usage

```bash
~/.claude/skills/safe-grep/bin/safe-grep [--dry-run] <pattern> <file>
```

- `--dry-run`: prints the command without executing
- `<pattern>`: a regex pattern (validated by `rg` before execution)
- `<file>`: path to the file to search

## Examples

```bash
# Search a session log for command patterns containing pipes
~/.claude/skills/safe-grep/bin/safe-grep '"command":"[^"]*\|[^"]*"' ~/.claude/projects/.../session.jsonl

# Preview what would run
~/.claude/skills/safe-grep/bin/safe-grep --dry-run 'foo|bar' somefile.txt
```

Output is full matching lines, same as `rg` default.
