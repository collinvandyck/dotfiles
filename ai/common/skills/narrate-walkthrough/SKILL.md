---
name: narrate-walkthrough
description: Investigate a code area and produce a spoken, single-narrator audio tour (mp3) of it, in the spirit of a NotebookLM audio overview. Use when the user wants to *listen* to a guided tour of a system, tool, PR, or code area rather than read one.
allowed-tools: Bash, Read, Grep, WebFetch
disable-model-invocation: true
user-invocable: true
---

# Overview

Produce a spoken guided tour of a code area — the audio sibling of `code-walkthrough`. You investigate the real code the same way, but you write for the ear from the first word and synthesize it to a single-narrator mp3. You never produce an eye-oriented walkthrough as an intermediate step.

The listener is not familiar with this code and wants a guided, documentary-style tour: calm, unhurried, dry. One narrator. No banter.

# Subject

The subject is in the user context below. It may be a system, a tool, a PR, or a code area. If no subject is given, ask the user what they want a tour of before doing anything else.

# Step 1: Investigate

Read the actual code to build genuine understanding — the same rigor as a written walkthrough. Use Read, Grep, and Bash to trace the real control flow, data structures, and entry points. Point yourself at what matters: how the thing works, why it is shaped that way, where the tricky parts are. Do not write anything for the listener yet.

# Step 2: Write the transcript (for the ear)

Write the narration as plain prose a person will read aloud. This is not a document with sections a reader skims; it is a script a narrator speaks start to finish.

Rules, non-negotiable:

- No code blocks. Describe what code *does* — its behavior and intent — never its syntax. "The flush path takes the current watermark and writes it alongside the batch" — not the function signature.
- No `file:line` references. Name things in words: "over in the bookie writer", not "boss_proxy.go line 212".
- No bullet lists, no tables, no ASCII diagrams. Everything is flowing sentences.
- Signpost transitions so the listener stays oriented without headings: "Now, here's where it gets interesting", "So far we've only talked about the happy path", "Step back for a second".
- Control pacing. Short sentences for the load-bearing ideas. Give a concept room before moving to the next.
- Register: dry, calm, unhurried. Documentary, not NPR. Sincere, quietly amused, never peppy.

Save the transcript to `~/code/narrations/<subject>.md`, where `<subject>` is a short kebab-case name for the tour. A single `#` title line at the top is fine; the synthesizer strips it.

# Step 3: Self-review, then synthesize

By default, do not stop for approval. Review the transcript yourself with fresh eyes against the rules above — no code blocks, no `file:line` refs, no bullets, no diagrams; dry documentary register; signposted transitions; faithful to what you investigated. Fix anything that's off, then go straight to Step 4.

The review gate is opt-in. Pause and hand the transcript to the user only if they explicitly asked to review or edit it before audio (e.g. "let me review it first", "show me the transcript before you cut it"). In that case, tell them the transcript's path and wait for their approval or edits before synthesizing.

# Step 4: Synthesize

Run the synthesizer. The first run downloads the Kokoro model (once, slow); later runs are fast.

    uv run --python 3.12 ~/.claude/skills/narrate-walkthrough/tts.py ~/code/narrations/<subject>.md

The mp3 lands at `~/code/narrations/<subject>.mp3`. Tell the user the path and offer to play it with `afplay`. Pass `--voice <name>` to override the narrator.

# User Context

$ARGUMENTS
