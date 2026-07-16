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

# Verifying claims

You are empowered to check out throwaway git worktrees to verify a claim — build the package, run the affected tests, read the real code at a specific ref. You **must** delete any worktree you create when you're done (`git worktree remove --force`, and delete the temp branch).

When a finding depends on code in another repo or service, be careful where you read that code from:

- **Go module dependencies are a good signal, but only for what they actually pin.** A repo usually depends on another service's *API/contract* module (proto types, generated clients) — not the service's *implementation*. The runtime behavior you care about (validation, business logic) often lives in an implementation module the PR's repo never imports, so no version string in the changeset tells you which behavior is live.
- **Do not trust `~/go/pkg/mod` for that implementation behavior.** The cached versions may be stale or landed there from an unrelated build. It's fast and looks authoritative; it is neither for this purpose.
- **Read the service's code at latest `origin/main`** (fetch first), or, better, the version actually deployed to the target environment/cell. That is the real source of truth for cross-service runtime behavior — the merge-base/go.mod discipline that governs the PR's own repo does not carry over to an independently deployed service.

Before you report a cross-repo finding, state which source you verified against (a specific ref, deployed version, or a build/test you actually ran) rather than "the code says." If you can't pin it down, say so and flag it as unverified instead of asserting it.

# User Context

$ARGUMENTS
