# narrate-walkthrough

The audio sibling of `code-walkthrough`. It investigates a subject — a system, tool, PR, or code area — writes a spoken narration for the ear (no code blocks, `file:line` refs, bullets, or diagrams), and synthesizes a single-narrator mp3 locally. Transcripts and audio collect in `~/code/narrations/`.

Invoke the full flow with `/narrate-walkthrough <subject>`: investigate, write the transcript, self-review it, then synthesize. By default it runs end to end; ask to review the transcript first and it pauses before audio.

## Synthesis

`tts.py` turns a transcript into an mp3. It's a self-contained `uv` script (deps pinned in its header), so the first run installs and the rest are fast.

```
uv run --python 3.12 tts.py <transcript.md> [--model NAME] [--voice V] [--speed S] [--ref-audio clip.wav] [--ref-text "..."] [--out path.mp3]
```

Output defaults to `~/code/narrations/<transcript-stem>.mp3`.

## Models

All run locally via `mlx-audio` on Apple Silicon. Add one by adding an entry to `MODEL_PRESETS` in `tts.py` — model repo, voice, `lang_code`, optional pinned `ref_audio`/`speed`, and any extra `generate_audio` kwargs — not by branching through `synthesize`.

- **kokoro** (default) — Kokoro-82M, voice `am_michael`. Fast (~4.5x real time), clean, the workhorse. No cloning, no register control.
- **cox** — Chatterbox zero-shot clone of Prof. Brian Cox at 0.9x, reference pinned to `_refs/brian-cox-light.wav`. Use for tours you want in his voice.
- **qwen3** — Qwen3-TTS CustomVoice. Register is steerable through the preset's `instruct` string, but it's ~2.4x slower than kokoro and reads flat unless the instruction is warm.
- **csm** — Sesame CSM, male base voice `conversational_b` at temperature 0.5. Natural timbre but stutters off conversational context, renders at ~real time (slow), and needs Hugging Face access to the gated `sesame/csm-1b` repo (accept the gate, then `hf auth login`).

Flags: `--voice` overrides the preset voice; `--speed` retimes with ffmpeg `atempo` (`<1` slower, `>1` faster — it slurs past ~0.9, so 0.9 is the practical floor); `--ref-audio`/`--ref-text` drive zero-shot cloning on models that support it (Chatterbox).

## Voice cloning

`--ref-audio <clip.wav>` clones a voice via Chatterbox from ~10-30s of clean solo speech. Reference clips live in `~/code/narrations/_refs/`. Keep real-person clones to personal use.

## Next step: OpenAI cloud voice (`gpt-4o-mini-tts`)

Add an `openai` model that calls OpenAI's `audio.speech` API instead of `mlx-audio`. The draw is steerable register — an `instructions` string ("calm, dry documentary narrator, unhurried, faint wry smile") that the model follows while reading the script verbatim — at higher quality than local qwen3, for ~$0.015/min (an 11-minute tour is about 17 cents). Voice `onyx` for a deep documentary read.

The wrinkle is the ~2000-token input cap (which counts the instructions, not just the text), so a full tour must be chunked:

1. Split the transcript on paragraph boundaries, never mid-sentence — our transcripts are already paragraph-structured, so the seams are free. Accumulate whole paragraphs into a chunk until it nears ~1,200-1,500 text tokens (count with `tiktoken`, don't eyeball), then start a new chunk.
2. Synthesize each chunk with the same voice and the same instructions, requesting WAV/PCM.
3. Concatenate the raw audio in order with a short (~300-400ms) silence between chunks — that hides join clicks and reads as a natural breath at the paragraph break — then encode to mp3 once. Optionally run ffmpeg `loudnorm` to even out level.

The inherent catch: each API call is independent, so prosody resets at every seam. Splitting only at paragraph breaks hides it (a pause there is expected); mid-paragraph splits would be audible. `loudnorm` fixes volume drift but not an intonation jump.

Two constraints to respect:

- **No cloning** — OpenAI is preset-voices only, so the Brian Cox clone stays local Chatterbox.
- **It's cloud — the transcript leaves the machine.** We chose local originally because the code walkthroughs are internal. Scope `openai` to non-internal material (general/topic tours); keep local kokoro/cox for internal code. OpenAI also requires disclosing that the voice is AI-generated.

Other cloud engines, if a key ever appears: **ElevenLabs** (best naturalness plus real voice cloning), **Gemini TTS** (multi-speaker, the NotebookLM engine), **Cartesia** (lowest latency). Anthropic has no TTS API — Claude writes the transcript but can't voice it.
