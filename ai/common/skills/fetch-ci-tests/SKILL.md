---
name: fetch-ci-tests
description: Use when you need to download CI artifacts and get a summary of test failures for a PR or run — fetches JUnit XMLs, test logs, and docker-compose logs
allowed-tools: Bash(*/fetch-ci-tests *)
---

# Fetch CI Test Artifacts

Downloads all CI artifacts for a PR or run, parses JUnit XML, and prints a structured summary of test failures.

**This is a data-fetching tool, not an analysis tool.** Run the script, return its output to the caller. Do not interpret the results or speculate on root causes — that is the job of the calling skill or the user.

## Usage

```bash
~/.claude/skills/fetch-ci-tests/bin/fetch-ci-tests (--pr <number|url> | --run <id>) [--repo owner/repo] [--dry-run]
```

- `--pr`: PR number or full GitHub URL
- `--run`: GitHub Actions run ID
- `--repo`: defaults to `temporalio/saas-temporal`
- `--dry-run`: show what would be fetched without downloading

## What it does

1. Resolves PR to its latest CI run
2. Downloads ALL artifacts (JUnit XMLs, test logs, docker-compose logs) to `/tmp/ci-tests/<run-id>/`
3. Parses JUnit XMLs for failures
4. Prints a summary to stdout: test name, artifact/shard, failure output

## After running

Report the script output and the artifact directory path. The artifacts are cached at `/tmp/ci-tests/<run-id>/`. Key paths for deeper investigation:

- Full test logs: `<artifact>/integration-test.log`
- Docker/container logs: `docker-compose-logs-<N>/`
- JUnit XML: `<artifact>/integration-test.junit.xml`

## Improving this skill

After completing an investigation, if you learned something that would help future investigations — patterns in failure messages, useful artifact paths, common root causes, or better diagnostic steps — suggest a concrete update to this skill file. The user can approve and commit it.

Examples of useful updates:
- "Connection refused errors in cross-region tests usually indicate a port-binding race in the test harness"
- "The docker-compose logs for shard N contain the Cassandra startup timing"
- "Walker tests use a different JUnit artifact naming pattern"
