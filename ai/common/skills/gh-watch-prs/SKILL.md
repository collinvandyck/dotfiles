---
name: gh-watch-prs
description: Use when asked to watch, babysit, or retry CI on one or more GitHub PRs with failing checks — wait for their builds to settle, fix failures the PR's own changes caused, rerun failures that look flaky, and keep going until they go green or a per-PR cap is hit.
allowed-tools: Agent, Read, Edit, Write, Skill, Bash(gh pr checks:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh run view:*), Bash(gh run list:*), Bash(gh run rerun:*), Bash(git:*), Bash(make:*), Bash(go:*), Bash(bash:*), Bash(awk:*), Bash(grep:*)
argument-hint: "[prs]"
disable-model-invocation: true
---

# Watch PRs, fix what we broke, retry what's flaky

Monitor one or more PRs: wait for each build to settle, then triage every failing check. When the PR's own changes caused the failure, fix it on the PR branch, commit, and push. When the failure looks flaky or infra-related, rerun the failed jobs. Keep going until the checks pass or a per-PR cap is reached.

Default caps per PR are 3 reruns and 2 fix attempts. The user can override either one.

Inputs: a list of PR numbers or urls

## Default: run this in the background

This can take many minutes per PR. Don't run the loop inline in the main conversation. Dispatch it to a background subagent so the user keeps an interactive session.

Use the `Agent` tool with `run_in_background: true` and a fresh, self-contained prompt. Use a regular agent, **not** a fork, and pass `model` explicitly as the main model (e.g. `opus`). Diagnosing a CI failure and writing the fix needs the main model, not Sonnet. Pass the PR numbers, the repo, both caps, and any context from the conversation about what the PR changes or why a check is failing. If the user already told you a failure comes from the PR's changes, say so in the prompt so the agent goes straight to a fix instead of spending a rerun to find out.

The dispatched agent's prompt should contain everything below ("The gh commands that matter" through "Report") plus the concrete PR list, repo, and caps. When you dispatch it, tell the user you're watching the PRs in the background and end your turn. The agent reports back on completion.

Only run the loop inline if the user explicitly asks you to watch in the foreground.

## The gh commands that matter

- `gh pr checks <PR> --repo <REPO>` — current check state. Tab-separated rows: `<name>\t<state>\t<duration>\t<url>`. States are `pass`, `fail`, `pending`, `skipping`. The build is **settled** when zero rows are `pending`.
- `gh run view <RUN_ID> --repo <REPO> --log-failed` — logs from the failed steps only. Pipe through `tail` or `grep`; the full log can be enormous.
- `gh pr diff <PR> --repo <REPO> --name-only` and `gh pr diff <PR> --repo <REPO>` — what the PR changes.
- `gh pr view <PR> --repo <REPO> --json headRefName,headRepositoryOwner` — the PR's branch.
- `gh run rerun <RUN_ID> --repo <REPO> --failed` — reruns only the failed jobs in a workflow run.

The run id is in each check's URL: `.../actions/runs/<RUN_ID>/job/<JOB_ID>`.

## Track each PR independently

Different PRs settle and retry on their own schedules. Keep per-PR rerun and fix counters, each against its own cap. Poll the PRs concurrently.

## Per-PR loop

For each PR, run this loop until it goes green or both caps run out:

1. **Wait for the build to settle.** Run the poll script below via Bash with `run_in_background: true`, so the harness re-invokes you when the build settles instead of blocking. Foreground `sleep` is blocked in this harness, but `sleep` inside a backgrounded command is fine.
2. **Find the failed runs.** From the settled `gh pr checks` output, take the rows whose state is `fail`, pull the `<RUN_ID>` out of each URL, and dedupe. Failures can span multiple workflow runs.
3. **If no failures, the PR is green.** Stop looping for this PR.
4. **Triage each failing check.** Read its `--log-failed` output and compare it with the PR diff. Classify it as one of:
   - **Caused by the PR.** The failure names a file, test, package, or generated artifact the PR changed, or it follows directly from the change: a test asserting the old behavior, a stale generated file, a lint error on a changed line, a compile error. A failure that repeats identically after a rerun also counts.
   - **Flaky or infra.** Timeouts, network errors, runner or registry failures, OOM-killed jobs, or a test in code the PR doesn't change and doesn't affect.
   - **Unclear.** Treat it as flaky the first time. If it fails the same way after a rerun, treat it as caused by the PR.
5. **Fix failures the PR caused** (see "Fixing a failure" below), if the PR is under its fix cap. Increment the fix count. A pushed commit starts a new CI build, so go back to step 1.
6. **Rerun flaky failures** with `gh run rerun <RUN_ID> --repo <REPO> --failed` for each affected run, if the PR is under its rerun cap. Increment the rerun count. Don't rerun a run that a fix commit in step 5 just replaced.
7. **If no action is left** (caps exhausted, or the failure can't be fixed safely), stop and record the still-failing checks for the report.
8. Go back to step 1.

## Fixing a failure

Work in a local checkout of the PR's branch:

1. Get the branch with `gh pr view`. Find the canonical clone of the repo under `~/code/temporal` and run `git worktree list` there. Use the worktree that already has the branch checked out. If none does, create one following the `git-worktrees` skill's conventions (a sibling of the root project, checking out the existing branch, not a new one).
2. If the worktree has uncommitted changes, don't touch it. Stop and report. Otherwise `git fetch` and `git pull --ff-only` so it matches the remote branch.
3. Follow the repo's `CLAUDE.md` for how to build, test, and regenerate files. Reproduce the failure locally first when the repo makes that cheap: run the failing test, generator, or lint target.
4. Make the fix with the Edit tool. Fix what the PR's change broke and nothing else. Typical fixes are regenerating checked-in output, updating a test or golden file that asserted the behavior the PR intentionally changed, or fixing a compile or lint error.
5. Re-run the same local check and confirm it passes.
6. Commit with the `git-create-commit` skill and push to the PR's branch with a plain `git push`.

Invoking this skill authorizes pushing fix commits to the PR's own branch, and only there. Never force-push, rewrite history, push to any other branch, or comment on the PR.

Stop and report instead of fixing when:

- The right fix would change what the PR does: reverting part of the change, or loosening a test that caught a real bug the PR introduced.
- The fix needs a decision only the user can make, or touches code far outside the PR's diff.
- The PR's head branch is in a fork you can't push to.
- The same check still fails after a fix attempt for the same reason. Don't retry the same idea.

## Poll-until-settled script

The same script serves the initial build wait, every rerun wait, and every wait after a fix push. Run it backgrounded, one per PR. After a push, wait until `gh pr checks` lists checks from the new head commit before trusting a "settled" result. Otherwise the script can report the old build as settled.

```bash
#!/bin/bash
# Wait until a PR has no pending checks, then print its final status (state\tname, sorted).
PR="$1"; REPO="$2"
while true; do
  OUT=$(gh pr checks "$PR" --repo "$REPO" 2>/dev/null)
  PENDING=$(echo "$OUT" | awk -F'\t' '{print $2}' | grep -c -E '^pending$')
  if [ -n "$OUT" ] && [ "$PENDING" -eq 0 ]; then
    echo "PR $PR: build settled."
    echo "$OUT" | awk -F'\t' '{print $2"\t"$1}' | sort
    exit 0
  fi
  sleep 30
done
```

After a push, start the poll only once CI has picked up the new commit. Compare `gh pr view <PR> --repo <REPO> --json headRefOid` with the `headSha` of the newest runs (`gh run list --repo <REPO> --branch <BRANCH> --json headSha,status --limit 5`), or wait about a minute before starting the poll.

To pull the failed run ids out of a settled checks listing:

```bash
gh pr checks "$PR" --repo "$REPO" 2>/dev/null \
  | awk -F'\t' '$2=="fail"{print $4}' \
  | grep -oE 'runs/[0-9]+' | grep -oE '[0-9]+' | sort -u
```

## Report

When every PR is done, report:

- Which PRs went green, and how: reruns, fixes, or both.
- Each fix commit: its short sha, the branch, what failed, and what the fix changed.
- Which PRs still fail, with each failing check name, its run URL, a few log lines showing the failure, and why it wasn't fixed (cap reached, needs a decision, outside the PR's scope).

## Common mistakes

- **Acting before settled.** Triage, reruns, and fixes only mean something once `pending` is zero. Always poll first.
- **Rerunning a deterministic failure.** A failure the PR caused fails the same way on every rerun. Read the log before spending a rerun.
- **Fixing a flake.** Don't change code to work around a timeout or a runner failure. Rerun it.
- **Changing the PR's intent to get green.** Loosening an assertion that caught a real bug, or reverting the change, is a decision for the user. Report it.
- **Trusting the old build after a push.** Wait for checks from the new head commit.
- **Sharing counters.** Each PR gets its own rerun and fix counters and caps.
- **Foreground sleep.** It's blocked here. Keep `sleep` inside the backgrounded poll command.
- **Rerunning the whole run.** Use `--failed` so passing jobs aren't re-executed.
- **Missing a second failing run.** Failures can be spread across runs. Dedupe run ids and handle each one.
