# import-conversations — design

## Purpose

Find Claude Code conversations across all of my projects, let me pick the relevant ones from a browser picker that shows a summary of each, and load cleaned renders of the chosen conversations directly into the *current* session — a way to "merge" context from several past conversations into one. Discovery stays cheap (firewalled); the import deliberately spends context and accepts compaction.

## Constraints that shaped the design

- Conversations are JSONL transcripts at `~/.claude/projects/<slug>/<uuid>.jsonl`. ~334 of them across ~33 projects, individual files up to ~7MB. The main session must never read a raw transcript directly.
- No pre-baked `summary` records exist in the transcripts, so matching works from prompts and content.
- Each record carries `cwd`, `gitBranch`, `timestamp`, `sessionId`, and message content. File mtime is last-activity. The first real user prompt is a cheap proxy for "what this was about."

## Pipeline

```
/import-conversations "the replay gameday + watermark work"
        │
        ▼
[1] index script   (mechanical, ZERO LLM tokens)
    scans ~/.claude/projects/*/*.jsonl, emits a compact skim
    bundle per convo: project · last-activity · size · msg-count
    · first prompt · last prompt · sampled user turns
        │
        ▼
[2] rank+preview sub-agent   (isolated context)
    reads ONLY the skim bundles, ranks by relevance × recency,
    caps top-N, writes a ~3-sentence preview per candidate
    → candidates.json
        │
        ▼
[3] browser picker   (serve_picker.py, blocks on submit)
    cards: project · date · size · preview + checkbox
    actions: "Import selected" | "Refine search" (+ text box)
        │
        ├──▶ refine → loop to [2] with the new query
        │
        ▼
[4] render_transcript.py   (mechanical, ZERO LLM tokens)
    renders each chosen transcript to balanced markdown
    (prose + condensed tool calls + truncated results)
    → stdout lands directly in the main session's context
        │
        ▼
[5] main agent continues with the conversations merged in
    (compaction, if any, is expected and fine)
```

The only LLM spent across the whole flow is the one Haiku rank+preview agent. Discovery never pulls a raw transcript or the full index into the main session. Import is the deliberate exception: `render_transcript.py` strips the JSONL to the actual conversation so loading it is affordable, then its output becomes the merged context. No digest sub-agents — the render is the import.

## Files

Skill lives at `~/.claude/skills/import-conversations/`.

- `SKILL.md` — orchestration instructions.
- `scripts/index_conversations.py` — mechanical skim of all transcripts. Flags: `--since`, `--project`, `--exclude-current <session-id>`, recency sort. Emits JSON. No LLM, no token cost. Reads only the slices of each file it needs so a 7MB transcript doesn't become a 7MB read.
- `scripts/serve_picker.py` — serves the picker HTML, opens the browser, blocks until I submit, prints `{"selected": [...]}` or `{"action": "refine", "query": "..."}` to stdout, then exits. Clean handoff, no polling. Also serves a `/transcript` drawer view.
- `scripts/render_transcript.py` — renders chosen transcripts to balanced markdown on stdout; this is the import step. No LLM.
- `scripts/transcript.py` — shared JSONL→turns parser used by both the picker drawer and the renderer.

## Skim bundle (per conversation, from the index script)

- `path`, `session_id`
- `project` — readable name derived from the record's `cwd`, not the mangled dir slug
- `last_activity` — file mtime
- `size_bytes`, `message_count`
- `first_prompt` — first real user prompt, trimmed (skips slash-command / system-reminder / caveat lines)
- `last_prompt` — last real user prompt, trimmed
- `sampled_turns` — a few evenly-spaced user turns, trimmed, to give the ranker more signal than first/last alone

## Import render (balanced fidelity)

`render_transcript.py` turns each chosen `.jsonl` into readable markdown: user + assistant prose, condensed tool calls (`→ Bash: ...`), and tool results truncated to ~600 chars (`← ...`). Raw JSON scaffolding is dropped. This is what gets read into the session. Larger conversations naturally produce more context — fidelity scales with the real conversation rather than a summary heuristic — and compaction absorbs overflow.

## Decisions

- **Recency bias on by default** — ranking weights recent conversations up unless I direct otherwise.
- **Self-exclusion** — the current live session's transcript is filtered out of candidates via `--exclude-current`.
- **Readable project names** — derived from each convo's `cwd`.
- **Refine in the browser** — picker has an "Import selected" action and a "Refine search" action with a text box; refine returns a new query and the pipeline re-ranks and re-serves. Chat-based refine also works.
- **In-context only** — v1 produces no file artifact; the renders land in the live session. Doc / structured-extraction outputs are deferred.
- **Candidate cap** — top ~12 by relevance × recency shown in the picker.
- **Render, don't digest** — chosen conversations are loaded by `render_transcript.py` (mechanical, balanced fidelity) directly into the session. No per-conversation LLM digest agents; the slow digest phase is gone, the cost is context tokens, and compaction is accepted.
- **User-invocable only** — `disable-model-invocation: true`; this runs when I type `/import-conversations`, never auto-triggered.
- **Scoped tools** — frontmatter `allowed-tools` grants only the three scripts (by path) plus `Agent`; the scripts are executable and the indexer takes `--out`, so the workflow needs no shell redirect or `mkdir`.
- **Picker UX** — editorial light theme; sorts by most-recent first by default (also oldest/largest/smallest/most-messages/best-match); each card has a "Read transcript" drawer that renders the full conversation by reading the `.jsonl` *in the picker process* (zero Claude context cost).
- **Fast ranking** — the rank+preview sub-agent runs on Haiku; it's now the only LLM in the flow and doesn't need deep reasoning. Further deferred speedups: query-aware mechanical shortlist before the LLM.

## Out of scope for v1

- Merged synthesis doc written to a file.
- Structured extraction (decisions / open questions / code / TODOs as lists).
- Full high-fidelity "resume this one thread" load.
- Persistent index cache across runs (the mechanical scan is cheap enough to run fresh each time).
