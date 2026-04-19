---
name: local-review
description: Perform a local review of this branch's changes
disable-model-invocation: true
allowed-tools: Bash, Read, WebFetch, Skill(superpowers:*)
---

# Overview

Use the superpowers:code-reviewer skill to perform a code review.

Get a sense of the commits via:

    git log --oneline $(git merge-base @ origin/main)..@

Before reporting a bug, confirm it by reading the relevant code paths — don't flag mismatches without checking which side is authoritative.
Do not take any action on any of the review items.
Present the findings to the user.

# User Context

$ARGUMENTS
