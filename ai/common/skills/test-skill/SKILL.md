---
name: test-skill
description: Test a skill's discoverability and execution by spawning fresh claude sessions
disable-model-invocation: true
argument-hint: "<skill-name>"
allowed-tools: Bash(printf *),Bash(claude -p *)
---

# Test a Skill

You are testing whether a skill works correctly when invoked by a fresh agent with no conversation context.

**Input:** `$ARGUMENTS` is the skill name to test (e.g. `safe-grep`).

## Step 1: Read the skill

Read the target skill's SKILL.md from `.claude/skills/$ARGUMENTS/SKILL.md`. Understand:

- What triggers it (from the `description` field)
- What tools it needs (scripts, Bash commands, etc.)
- What a successful invocation looks like

## Step 2: Design test prompts

Create three test scenarios:

1. **Explicit invocation** — directly invoke the skill via `/$ARGUMENTS <args>` with realistic arguments
2. **Implicit discovery** — a natural prompt that *should* trigger the skill based on its description, without mentioning the skill name
3. **Negative control** — a prompt that should *not* trigger the skill

For each, determine:
- The prompt to send
- The `--allowedTools` whitelist: include tools the skill needs (e.g. `Bash(*/safe-grep *)`) plus `Read,Skill`. Exclude tools the agent might use *instead* of the skill (e.g. exclude `Grep` if testing `safe-grep`)
- What success looks like

## Step 3: Run tests

For each scenario, pipe the prompt via `printf` to avoid shell interpretation of special characters:

```bash
printf '%s' '<prompt>' | claude -p \
  --output-format json \
  --permission-mode dontAsk \
  --model haiku \
  --allowedTools "<tools>" 2>&1
```

**IMPORTANT:** Never pass the prompt as a positional argument — special characters like `|`, `"`, and `/` break shell parsing. Always use `printf '%s' '<prompt>' | claude -p ...`.

Parse the JSON result and extract:
- `result` — what the agent produced
- `num_turns` — how many iterations
- `permission_denials` — what tools were blocked (shows what the agent tried but couldn't use)
- Whether the skill was invoked (check if `result` reflects skill behavior)

## Step 4: Report

For each scenario, report:

```
### Test N: <scenario type>
Prompt: <what was sent>
Allowed tools: <whitelist>
Result: PASS / FAIL
  - Skill invoked: yes/no
  - Permission denials: <list or none>
  - Agent output: <summary>
  - Turns: <N>
  - Cost: <$X.XX>
```

Then summarize:
- **Explicit invocation**: does it work when directly called?
- **Implicit discovery**: does the agent find it from a natural prompt?
- **Negative control**: does it correctly *not* trigger?
- **Recommendations**: frontmatter changes, description improvements, or CLAUDE.md additions needed

## Notes

- Use `--model haiku` for cost efficiency unless the user specifies otherwise
- The `--permission-mode dontAsk` + `--allowedTools` combination is what makes this work: the agent can only use whitelisted tools, and anything else shows up in `permission_denials`
- If implicit discovery fails, that's diagnostic — it means the skill description doesn't match the agent's natural approach to the problem
