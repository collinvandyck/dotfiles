---
name: import-conversations
description: Use when the user wants to find, load, summarize, or merge context from past Claude Code conversations — across any project — into the current session by describing what they're looking for rather than naming files. Triggers on "import conversations", "pull in that other chat", "merge those sessions", "load context from my other projects".
disable-model-invocation: true
allowed-tools: Bash(*/index_conversations.py *), Bash(*/serve_picker.py *), Bash(*/render_transcript.py *), Agent
---

# import-conversations

## Overview

Find past Claude Code conversations across all projects, let the user pick the relevant ones from a browser picker that shows a summary of each, then load cleaned renders of the chosen conversations straight into the **current** session — a way to merge context from several past conversations into one.

**Cheap discovery, deliberate import — the core idea:** keep *finding and picking* nearly free, then load only what the user chose.

- **Discovery is firewalled.** While finding and ranking, the **main loop** (you, orchestrating) must NEVER pull a raw `.jsonl` transcript (~7MB) or the full `index.json` into its own context. A script skims for zero tokens; the ranking **sub-agent** reads the index in its own isolated context and hands back a small result.
- **Import is intentional.** Once the user picks, you load the chosen conversations into *this* session on purpose — via `render_transcript.py`, which strips the JSONL down to the actual conversation (balanced fidelity: prose + condensed tool calls + truncated results), not the raw multi-MB file. This costs real context; if it triggers compaction, that's expected and fine. There are no digest sub-agents — the render IS the import.

Never read a raw `.jsonl` or the full index directly even at import time — always go through `render_transcript.py`, which is what keeps a 7MB file from becoming 7MB of context.

## When to use

- "Import / pull in / merge those other conversations about X"
- "Load the context from my work on Y in the other project"
- Reconstructing a thread of work that's spread across sessions or repos.

Not for: searching one known file (just read it), or resuming a single session verbatim (use Claude Code's own resume).

## Workflow

Paths used below: scratch dir `/tmp/import-conversations/$CLAUDE_CODE_SESSION_ID/`, skill dir `~/.claude/skills/import-conversations/`. `$CLAUDE_CODE_SESSION_ID` is an env var (it persists across Bash calls); shell vars you assign inline do NOT persist, so keep each command self-contained.

### 1. Index (main agent, mechanical, zero tokens)

Run the skim. It writes the index file (creating the scratch dir) and prints only a count to stderr. **Do NOT `cat` the index into context** — it's large; you never need to read it, the ranking sub-agent does.

```bash
~/.claude/skills/import-conversations/scripts/index_conversations.py \
  --exclude-current "$CLAUDE_CODE_SESSION_ID" --min-messages 2 \
  --out /tmp/import-conversations/$CLAUDE_CODE_SESSION_ID/index.json
```

Add `--project <substr>`, `--since YYYY-MM-DD`, or `--limit N` if the user scoped the search. Recency sort is the default. Run with `--help` for all flags.

### 2. Rank + preview (sub-agent)

Dispatch ONE sub-agent **on a fast model (Haiku)** — pass `model: "haiku"` to the Agent tool. Ranking and short previews aren't deep-reasoning work, and this single agent is the main latency cost of the whole flow, so the fast model is what keeps it snappy. It reads `/tmp/import-conversations/$CLAUDE_CODE_SESSION_ID/index.json`, ranks against the user's description, and writes `candidates.json` beside it. It works **only from the skim bundles — it must not open any transcript.** Give it this contract:

- Rank primarily by relevance to the query; use recency to break near-ties and lift recent matches (bias recent up unless the user said otherwise). This is a judgment call, not a formula.
- **Relevance floor: do NOT pad to a fixed count.** Keep only conversations genuinely on-topic, up to ~12. If only 4 truly fit, return 4. Better a short honest list than filler.
- Write `{"query": "<the user's description>", "candidates": [...]}`, candidates ordered best-first (`relevance`/"Best match" sort renders this order). Each candidate copies these metadata fields verbatim from the index entry — `session_id`, `path` (the `.jsonl` transcript path), `project`, `last_activity`, `last_activity_date`, `size_bytes`, `size_human`, `message_count` — and adds a `preview`: 2–4 plain sentences of what the conversation was about, written from `first_prompt` and `sampled_turns` (these are human text; `last_prompt` can help but ignore it if it's short/duplicated boilerplate). Drop the bulky `cwd`/`first_prompt`/`last_prompt`/`sampled_turns` from the output — the picker doesn't need them.
- Return only a one-line count — not the candidates themselves.

If too few good matches come back, re-dispatch with broadened terms before showing the picker.

### 3. Pick (main agent)

Open the browser picker and capture its stdout (it blocks until the user submits):

```bash
~/.claude/skills/import-conversations/scripts/serve_picker.py \
  /tmp/import-conversations/$CLAUDE_CODE_SESSION_ID/candidates.json
```

The picker sorts by most-recent first (with other sort options), and each card has a "Read transcript" view that renders the full conversation in a drawer — that read happens inside the picker process, not your context, so it costs no tokens. The result on stdout is one of:
- `{"selected": [<full candidate objects>]}` → go to step 4.
- `{"action": "refine", "query": "..."}` → go back to step 2 with the new query, then re-open the picker.

### 4. Import (main agent — load into this session)

Render the chosen transcripts and let the output land in your context. Pass every selected `path` to one invocation; its stdout is the import:

```bash
~/.claude/skills/import-conversations/scripts/render_transcript.py \
  <path-1> <path-2> ...
```

The script emits balanced markdown per conversation (a header, then prose + condensed tool calls + truncated results), zero LLM and near-instant. Big conversations produce a lot of text — that's the point, and compaction handling it is expected. No sub-agents, no digesting.

### 5. Continue (main agent)

The conversations are now loaded in this session. Briefly tell the user what came in (project · date, one line each) and that you're ready to keep working with that context merged in. Don't re-summarize it at length — it's already here.

## Red flags — STOP

- About to `cat`/`Read` a raw `.jsonl` transcript or `index.json` directly → don't. During discovery the ranking sub-agent reads the index; at import you go through `render_transcript.py`. Reading the raw file is what blows out context.
- About to write the per-candidate previews yourself by reading transcripts → no; previews come from skim bundles in the ranking sub-agent.
- About to summarize the imported conversations after loading them → no; the render is already in context. Just continue the work.
- Skipping the picker and auto-importing your top guesses → no; the user chooses.

## Common mistakes

- **Reading the raw `.jsonl` instead of rendering it.** A raw transcript is mostly tool-call JSON; `render_transcript.py` is what makes the import affordable.
- **Empty previews.** The index already falls back to the slash-command for command-initiated sessions, so a blank `first_prompt` means a genuinely contentless convo — fine to rank low.
