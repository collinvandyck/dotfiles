---
name: scaffold-script
description: Create a new shell-script-backed skill with permission wiring and verification
disable-model-invocation: true
argument-hint: "[description of what the script should do]"
---

# Scaffold a Script-Backed Skill

You are creating a new user-level skill that's backed by a shell script. The
skill lives at `~/.claude/skills/<name>/` and its script lives inside that
skill's own `bin/` directory. Follow these five phases in order. Do not skip
or combine phases.

If `$ARGUMENTS` is provided, use it as the starting description for Phase 1. Otherwise, ask the user what they need.

## Phase 1: Understand

Before writing anything, establish:

1. **What problem does this solve?** Look at conversation context — was a command just rejected by a hook? Is the user describing a repeated task?
2. **What triggers it?** When would an agent reach for this? What symptoms, situations, or keywords?
3. **What are the inputs?** Arguments, stdin, environment variables, files.
4. **What are the outputs?** Stdout, files created, side effects.
5. **What could go wrong?** Missing dependencies, permissions, destructive operations.

Summarize your understanding back to the user. Get confirmation before proceeding.

## Phase 2: Draft the Script

Write the shell script following these conventions:

- Shebang: `#!/usr/bin/env bash` (or zsh if needed)
- `set -euo pipefail`
- Support `--dry-run` flag
- Brief usage comment at the top
- One script, one job

```bash
#!/usr/bin/env bash
# <one-line description>
# Usage: <script-name> [--dry-run] <args>
set -euo pipefail

DRY_RUN=false
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then DRY_RUN=true; else ARGS+=("$arg"); fi
done

# Use: if $DRY_RUN; then echo "would do X"; else do X; fi
```

Present the draft. Iterate until the user is satisfied.

## Phase 3: Draft the Skill

Write the SKILL.md for the new skill. The frontmatter is critical:

- `description`: Start with "Use when..." — triggering conditions only, not what the skill does
- Stay under 250 characters (truncation threshold in skill listings)
- Include keywords agents would search for

The body should explain how to invoke the script and what `--dry-run` shows. Do not duplicate the script logic — point to the script, explain its interface.

Present the draft. Iterate until the user is satisfied.

## Phase 4: Create and Wire

Once both drafts are approved, execute all of these:

1. Create the skill directory: `mkdir -p ~/.claude/skills/<name>/bin`
2. Write the script to `~/.claude/skills/<name>/bin/<name>`
3. `chmod +x ~/.claude/skills/<name>/bin/<name>`
4. Write SKILL.md to `~/.claude/skills/<name>/SKILL.md`. In the body, reference
   the script at `~/.claude/skills/<name>/bin/<name>`.
5. If the script needs an allowlist entry, add `Bash(*/<name> *)` to the
   `permissions.allow` array in `~/.claude/settings.json` (or `settings.local.json`
   if project-scoped).

Note: `~/.claude/skills/` on this machine is a symlink into the dotfiles repo,
so creating files under it will land inside `~/.dotfiles/ai/common/skills/`.

## Phase 5: Verify

Run these checks and report results:

1. `test -x ~/.claude/skills/<name>/bin/<name>` — script is executable
2. `~/.claude/skills/<name>/bin/<name> --dry-run` with representative args — dry-run works
3. `python3 -c "import json; json.load(open('$HOME/.claude/settings.json'))"` — valid JSON (if settings.json was touched)
4. Frontmatter lint: `name` is kebab-case letters/numbers/hyphens, `description` starts with "Use when", total frontmatter under 1024 chars

If any check fails, fix it before finishing. Then commit all new files.

## Conventions

- Script names: kebab-case (`search-sessions`, `grep-jsonl`)
- Skill directory matches script name; script lives in `<skill>/bin/<script>`
- Every script supports `--dry-run`
- Scripts are self-contained
