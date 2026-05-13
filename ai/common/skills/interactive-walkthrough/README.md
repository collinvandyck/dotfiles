# interactive-walkthrough

Renders a code walkthrough as a self-contained, interactive HTML page. Same intent as the `code-walkthrough` skill, different output format.

## What's here

- `SKILL.md` — the skill definition.
- `skeleton.html` — the visual chrome (dark theme, syntax highlighting, ASCII-diagram styling, gotcha/note blockquotes, collapsible deep-dives, TOC, hero, footer). Always the starting point. Open it in a browser to see what the bare scaffolding looks like.

## What's not here (yet)

### `patterns/` directory

The first iteration of this skill bundles no reusable interactive patterns. The simulator from the esreindex walkthrough lives only in the source file it was generated alongside. Once a second walkthrough wants the same shape of widget, codify it as a standalone HTML/CSS/JS fragment under `patterns/`, with a short README naming the mechanic it's good for.

Candidate patterns worth harvesting when the use case justifies it:

- **Simulator** — animate state changes against a small board (concurrency gates, queue drains, signal-driven mutations, batch admission, retry/backoff). The esreindex page is the reference implementation.
- **State machine** — nodes + transitions with current-state highlighting.
- **Sequence step-through** — numbered call flow you can advance one step at a time.
- **Code comparison toggle** — before/after, with/without X, or the same operation across multiple languages.
- **Annotation hover** — hover a code line, see an explanation in a side panel.
- **Flow tracer** — highlight one execution path through an ASCII diagram on click or hover.

The deliberate choice is to *earn* each pattern by needing it once, rather than pre-baking a menu the model is tempted to pick from when nothing actually fits.

### Other things considered, not built

- **Light theme toggle.** Dark works for every case so far. Add when someone needs it on a projector or in print.
- **In-page search / filter.** Cmd-F until proven inadequate.
- **Multi-file index page.** The Obsidian vault already indexes generated walkthroughs by folder.
- **Print / PDF stylesheet.** Add when asked.
- **Non-Go syntax highlighting.** The skeleton's highlighter handles Go and `sh`. Extend the JS at the bottom of `skeleton.html` when a walkthrough needs another language. Python, TS, and SQL are the most likely candidates.
- **Linking to external docs.** Inline links are fine, but the page should still be readable offline. Don't embed an `<iframe>`.

## Anti-patterns

- Don't add a simulator (or any interactive widget) to a walkthrough whose subject is a data structure, file layout, config schema, or one-shot procedure. Static-with-good-chrome is the right answer there.
- Don't replace the chrome's visual language to match a specific topic. Extend it (new tokens, new section types) rather than rewriting it.
- Don't pull in external CSS or JS frameworks. The file should render with no network.
- Don't lean on color alone for meaning in the gotcha/note blockquotes — the `<strong>` label inside (`Gotcha.`, `Note.`) carries the signal for readers who can't distinguish red from blue.

## Quality bars

- **Self-contained.** One HTML file. No CDN, no remote fonts, no images that aren't inline SVG or data URIs.
- **Static-is-fine.** A well-styled, syntax-highlighted, collapsible-organized walkthrough with zero interactive widgets is a valid output.
- **Interactivity is earned by the mechanic, not by ambition.** The simulator in the esreindex page was great because the mechanic (signal flips `MaxConcurrency`, gate loop watches it, in-flight count drains) is genuinely simulatable. Most code isn't.

## Iterating on this skill

After generating a few walkthroughs against the skeleton, expect to:

1. Add patterns to `patterns/` when one recurs.
2. Extend `skeleton.html` if a chrome element is needed across walkthroughs (e.g., a sidebar, a glossary block).
3. Sharpen the SKILL.md prompt when the model makes a recurring judgment call wrong (e.g., adds a simulator where none fits, or skips one where one would have helped).
