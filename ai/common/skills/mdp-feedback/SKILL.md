---
name: mdp-feedback
description: Use when the user wants to review markdown in the browser and have you act on their comments through gh-markdown-preview (mdp) — "open these docs for review", "let me leave comments on X", "start mdp with feedback", "watch feedback", "listen for my comments", "start the feedback loop". Starts the mdp server with --feedback if needed, runs a background waiter, applies each submitted batch of comments to the markdown files, replies on each thread, and waits for the next batch.
---

# mdp feedback loop

The user reviews rendered markdown in `mdp --feedback` (`~/code/gh-markdown-preview/preview.py`). They highlight text or click the + beside a block, leave comments, and press **Submit feedback**. Each submit is a batch. Your job is to start the preview when they haven't, pick batches up, make the edits, and answer each thread in the page. Live reload shows your edits; the page polls for your replies.

## Commands

Always call the script by its absolute path, with nothing in front of it (no `cd ... &&`, no env vars). The permission allow rule matches that exact prefix, so this keeps the loop prompt-free. The `mdp` alias doesn't exist in your shell.

```sh
/Users/collin/code/gh-markdown-preview/preview.py feedback roots                     # served roots with feedback, and whether anyone is listening
/Users/collin/code/gh-markdown-preview/preview.py feedback wait --root ROOT          # block until a batch arrives, claim it, print it
/Users/collin/code/gh-markdown-preview/preview.py feedback show --root ROOT          # open threads with their messages
/Users/collin/code/gh-markdown-preview/preview.py feedback reply --root ROOT THREAD "text"
/Users/collin/code/gh-markdown-preview/preview.py feedback reply --root ROOT THREAD --body-file FILE
/Users/collin/code/gh-markdown-preview/preview.py feedback move --root ROOT THREAD --line N [--file FILE] [--quote "text"]
```

ROOT is the served root, usually the git toplevel of the worktree being previewed. The server prints it at startup, `roots` lists it, and every batch repeats it.

## Starting the preview

Start the server yourself unless the user says one is already running with `--feedback`. A server the user started without `--feedback` doesn't collect comments, so start a new one rather than reuse it.

1. Work out PATH: the file or folder the user wants to review. A folder opens on its README or index.
2. Run it with `run_in_background: true` so it outlives the turn, through `python3` so the existing `python3` allow rule covers it:
   ```sh
   python3 /Users/collin/code/gh-markdown-preview/preview.py PATH --feedback
   ```
   Leave off `--no-open`. The server opens the page in the user's browser. Each run gets its own port, so this never collides with another preview.
3. Read the task's output file. The server prints `serving ROOT`, `open URL`, and the exact `feedback wait` command for that root. Take ROOT from there. Don't guess it.
4. Tell the user the URL, then start the waiter (step 1 of the loop) in the same turn.

If you already started a server for the same root earlier in this session and it's still running, reuse it. Don't start a second one.

## The loop

1. Start `feedback wait --root ROOT` with `run_in_background: true`. Don't poll it and don't sleep. You're notified when it exits, which happens when the user submits.
2. When it exits, read its output. Each thread gives the file's absolute path, the line range when the comment was made, the quoted text (or "none" for a whole-block comment), the source of those lines at the time, and the message history. Messages marked `(new)` are this batch.
3. Handle every thread in the batch:
   - Lines shift as you edit, so find the spot by the quote and the source excerpt, not the line numbers alone.
   - Make the change the comment asks for, in the file's existing style and following any writing rules that apply to that repo.
   - Reply on the thread. Say briefly what you changed. If the request is ambiguous or you disagree, ask or explain in the reply instead of guessing. If the comment is a question, answer it.
   - Use `--body-file` for long or multi-line replies, written to a file in your scratchpad with the Write tool.
   - If your edit rewords the quoted text, moves it, or moves it to another file, the thread loses its anchor and the page marks it outdated. Run `feedback move` to point it at where that content lives now. `--line` is any source line in the new block, `--file` is the new file if it changed (relative to ROOT or absolute), and `--quote` is the new rendered text to highlight: what the page shows, so no backticks or link syntax. For a diagram thread, `--quote` is the new label. Leave `--quote` off if the quoted text didn't change, and always leave it off for a whole-block thread. The page turns the line into a full anchor the next time it renders that file. Skip `move` when the content is simply gone, and say so in the reply.
4. Never resolve threads. The user resolves them, usually after checking your edit.
5. Start the next `wait` in the background right away, in the same turn. Starting it also marks the batch you just handled as done, which clears "Agent is working" in the page.
6. Give the user a short summary in the terminal of what changed per thread.

Keep going until the user says to stop. Then stop the background waiter, and the server too if you started it. Comments stay in the database, so a later session can pick up open threads with `show`.

If the server task exits while you're looping, tell the user. Their page stops reloading and can't submit anything until you start it again.

## Notes

- A batch can hold replies on older threads. Read the whole history, not just the new message, before acting.
- Don't commit after each batch unless the user asked for that.
- If `wait` prints "No feedback in ...", it was started with `--timeout`. Start it again.
