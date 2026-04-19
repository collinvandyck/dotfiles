---
name: debug-ci
description: Debug CI test failures or flaky tests on a PR
disable-model-invocation: true
argument-hint: "<pr-number|pr-url|run-id>"
model: opus[1m]
allowed-tools: Bash(*/fetch-ci-tests *)
---

# Debug CI Test Failures

You are investigating why CI tests failed or were flaky on a PR or run.

## Step 1: Fetch the data

Invoke the fetch-ci-tests script to download artifacts and get a failure summary:

```bash
~/.claude/skills/fetch-ci-tests/bin/fetch-ci-tests --pr $ARGUMENTS
```

If `$ARGUMENTS` looks like a run ID (large number), use `--run` instead of `--pr`.

## Step 2: Identify the failures

From the script output, note:
- Which tests failed
- Which shard/artifact they came from
- Whether they were retried (look for "retry" in test names or multiple failures for the same test)

## Step 3: Read the evidence

For each failed test, read the relevant files from the artifact directory:

1. **Failure output** from the script summary (first pass)
2. **Full test log** at `<artifact>/integration-test.log` — search for the test name to find the full output including setup, teardown, and surrounding context
3. **Docker-compose logs** at `docker-compose-logs-<N>/` if the failure suggests infrastructure issues (connection refused, timeouts, service unavailable)

## Step 4: Build theories

Create up to three theories for each failure, ranked by likelihood. For each theory:
- State the hypothesis
- Cite specific evidence from the logs
- Explain what would confirm or rule it out

**Work from first principles.** Read the actual error messages and log context. Do not assume the cause matches a known pattern.

## Step 5: Cross-reference known patterns

After forming your theories, read [known-patterns.md](known-patterns.md) and compare. Note if any of your theories match known patterns, but do not discard theories that don't match — novel failures are common.

## Step 6: Suggest next steps

Present your theories and ask the user what to do next. Options typically include:
- Read more logs to narrow down theories
- Attempt to reproduce locally with `tst <TestName>`
- Look at recent changes to the test or code under test
- Check if this test has a history of flakiness

Do NOT attempt to fix the code or run tests without the user's direction.

## Improving this skill

If you learned something during this investigation that would help future investigations, suggest updates to:
- **This file**: for process improvements
- **[known-patterns.md](known-patterns.md)**: for new failure patterns or ignore-list entries
