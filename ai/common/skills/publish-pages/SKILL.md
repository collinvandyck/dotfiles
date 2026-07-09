---
name: publish-pages
description: Use when asked to publish, deploy, ship, or push a page or asset to the Temporal pages repo (temporalio/pages, ~/code/temporal/pages) and see it live — pushes to main, waits for the GitHub Pages CI build, then prints and opens the deployed GitHub Pages URL.
---

# Publish Pages

## Overview

The `temporalio/pages` repo is a static GitHub Pages site. There is no pull request — you push to `main`, a GitHub Actions workflow (`pages.yml`) builds and deploys, and the content becomes live at a GitHub Pages URL. This skill takes committed work from staged to live-and-opened-in-a-browser.

The Pages base URL is **not guessable** — the repo is private, so GitHub serves it from a random `*.pages.github.io` subdomain. Always resolve it from the API (the helper script does this); never hardcode it.

## Workflow

Compose the commit message (in the user's writing style) and decide which paths to publish — that's the only part needing judgment. Then hand the whole thing to the helper as **one background command** and move on.

**Run the helper in the background.** Invoke it as a Bash command with `run_in_background: true` from inside the pages checkout. Backgrounding is the default: the build wait takes ~30–60s, and the helper runs in the main agent's own process (not a subagent), so it keeps this conversation's context while freeing the turn to continue. You'll be re-notified when it exits.

```sh
~/.claude/skills/publish-pages/publish.sh -m "commit message" [path ...]
```

It does everything: `git add` + `git commit` (when `-m` is given) → `git pull --rebase` → `git push` → wait for the run whose `headSha` matches the pushed commit → `gh run watch --exit-status` → resolve the base URL → print and `open` the URL(s).

- Pass `-m` to commit in the same step (stages the given paths, or `git add -A` if none). Omit `-m` only if you've already committed.
- **Report the URL** it prints once the background command completes.

## Choosing what to open

- **No args:** opens every `.html` file changed in the HEAD commit. Good default when you just added/edited one or a few pages.
- **Explicit paths:** pass repo-relative paths to control what opens. A directory opens its index (`collin/foo/` → `<base>/collin/foo/`); a file opens directly (`collin/foo.html` → `<base>/collin/foo.html`).

Prefer passing the specific path when you added a whole folder, so the landing page opens rather than each asset.

## Common mistakes

- **Dirty tree without `-m`.** The rebase fails on uncommitted changes. Either pass `-m` so the helper commits first, or commit yourself before running it.
- **Hardcoding the URL.** It changes per repo and is private/random. Let the script read it from `gh api repos/temporalio/pages/pages`.
- **Guessing the run.** Don't watch "the latest run" blindly — a concurrent push could mismatch. The script matches on the pushed commit's SHA.
