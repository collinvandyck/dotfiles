---
name: local-pr-review
description: Perform a local review of a PR
allowed-tools: Bash, Read, WebFetch, Skill(write-generated-doc)
disable-model-invocation: true
argument-hint: "<PR number or url>"
---

# Overview

Your goal is to review the supplied PR in a local fashion.

# Details

- First read the PR description and any existing comments.
- Then start reading the changes.
- Focus on correctness and code style, in that order.
- For potential issues found:
    - Be sure that it's an actual issue. Think hard if you need to.
    - Do not report correctness issues that are actually safe.
    - Use analogies and visual diagrams when appropriate
    - diagrams should be ascii-art inside of fenced code blocks
    - use fenced code blocks to showcase relevant code snippets to increase understanding
    - Keep explanations conversational. For complex concepts, use multiple analogies.

If you need additional information from the user, ask beforehand.
Finally, write the generated doc and open it.

# Branch

Exploring the code locally is fine, but you should do so against the merge base of that branch.
The current branch in this repo may have code that's not relevant to the PR. If you need to check out
the code, check it out in a temporary directory. Avoid making local changes.

# User Context

$ARGUMENTS
