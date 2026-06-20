---
name: gh-watch-prs
description: Use when asked to watch, babysit, or retry CI on one or more GitHub PRs with failing checks — wait for their builds to settle, rerun the failed jobs, and keep retrying until they go green or a per-PR retry cap is hit.
allowed-tools: Agent, Bash(gh pr checks:*), Bash(gh run rerun:*), Bash(bash:*), Bash(awk:*), Bash(grep:*)
argument-hint: "[prs]"
disable-model-invocation: true
---

# Watch PRs and retry failing CI

Monitor one or more PRs that have failing CI: wait for each build to settle, rerun the failed jobs, and keep retrying until the checks pass or a per-PR cap is reached. Default cap is 3 reruns per PR (configurable — ask or accept an override).

Inputs: a list of PR numbers or urls

## Default: run this in the background

This can take many minutes per PR. Don't run the loop inline in the main conversation — dispatch it to a background subagent so the user keeps an interactive session.

Use the `Agent` tool with `run_in_background: true` and a fresh, self-contained prompt. Pass the PR numbers, the repo, and the per-PR cap directly — a regular agent, **not** a fork. The watch loop needs none of the parent conversation, so a fork would only drag in context the subagent never uses. The background agent gets re-invoked automatically when its own backgrounded poll scripts exit, which is exactly what this loop needs.

The dispatched agent's prompt should contain everything below ("The two gh commands that matter" through "Report") plus the concrete PR list, repo, and cap. When you dispatch it, tell the user you're watching the PRs in the background and end your turn — the agent reports back on completion.

Only run the loop inline if the user explicitly asks you to watch in the foreground.

## The two gh commands that matter

- `gh pr checks <PR> --repo <REPO>` — current check state. Tab-separated rows: `<name>\t<state>\t<duration>\t<url>`. States are `pass`, `fail`, `pending`, `skipping`. The build is **settled** when zero rows are `pending`.
- `gh run rerun <RUN_ID> --repo <REPO> --failed` — reruns only the failed jobs in a workflow run.

The run id lives in each check's URL: `.../actions/runs/<RUN_ID>/job/<JOB_ID>`.

## Track each PR independently

Different PRs settle and retry on their own schedules. Keep a per-PR rerun counter — each PR retries against its own cap, not a shared one. Poll the PRs concurrently.

## Per-PR loop

For each PR, run this loop until it goes green or its rerun count hits the cap:

1. **Wait for the build to settle.** Use the poll script below via Bash with `run_in_background: true`, so the harness re-invokes you when the build settles instead of blocking. Foreground `sleep` is blocked in this harness, but `sleep` inside a backgrounded command is fine.
2. **Find the failed runs.** From the settled `gh pr checks` output, take the rows whose state is `fail`, pull the `<RUN_ID>` out of each URL, and dedupe. Failures can span multiple workflow runs, so collect the distinct run ids that have at least one `fail`.
3. **If no failures, the PR is green.** Stop looping for this PR.
4. **If at the cap, stop.** Record the still-failing check names and their URLs for the report.
5. **Rerun.** `gh run rerun <RUN_ID> --repo <REPO> --failed` for each affected run. Increment the PR's rerun count.
6. **Wait for the reruns to settle** (same poll script) and go back to step 2.

## Poll-until-settled script

Same script serves both the initial build wait and every rerun wait. Run it backgrounded, one per PR.

```bash
#!/bin/bash
# Wait until a PR has no pending checks, then print its final status (state\tname, sorted).
PR="$1"; REPO="$2"
while true; do
  OUT=$(gh pr checks "$PR" --repo "$REPO" 2>/dev/null)
  PENDING=$(echo "$OUT" | awk -F'\t' '{print $2}' | grep -c -E '^pending$')
  if [ "$PENDING" -eq 0 ]; then
    echo "PR $PR: build settled."
    echo "$OUT" | awk -F'\t' '{print $2"\t"$1}' | sort
    exit 0
  fi
  sleep 30
done
```

To pull the failed run ids out of a settled checks listing:

```bash
gh pr checks "$PR" --repo "$REPO" 2>/dev/null \
  | awk -F'\t' '$2=="fail"{print $4}' \
  | grep -oE 'runs/[0-9]+' | grep -oE '[0-9]+' | sort -u
```

## Report

When every PR is done, report:

- Which PRs went green.
- Which still have failures after exhausting their reruns.
- For the failures: the failing check names and their run URLs.

## Common mistakes

- **Acting before settled.** Reruns and failure assessment only mean something once `pending` is zero. Always poll first.
- **Sharing a retry counter.** Each PR gets its own counter and its own cap.
- **Foreground sleep.** It's blocked here. Keep `sleep` inside the backgrounded poll command.
- **Rerunning the whole run.** Use `--failed` so passing jobs aren't re-executed.
- **Missing a second failing run.** Failures can be spread across runs — dedupe run ids and rerun each one.
