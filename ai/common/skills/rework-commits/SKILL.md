---
name: rework-commits
description: Rewrite the commits on this branch in reviewer-first style
allowed-tools: Bash, Read, WebFetch
context: fork
model: sonnet[1m]
disable-model-invocation: true
---

# Overview

Your task is to rework the commits on this branch in RFPR (Reviewer First Pull Request) style.
Fetch and understand this blog post: https://5xx.engineer/2025/02/13/rfprs.html.
Create a set of new commits on this branch so that they tell a story in RFPR style.

## Guidance

- If there are uncommitted changes, ask the user if they want to include them as well.
- The most important takeaway is that the reviewer should be able to easily review the commits in order.
- Do not create a PR -- only rework the commits.
- Related changes across files often are better suited to be in the same commit rather than a commit per file.
- Supporting changes should be earlier than the primary changes in the commit list.
- For large diffs, focus intensely on more granular commits.

### Guidance: Intermediate LSP Noise and Build Errors

It's not important that each granular commit should build or lint. The most important things is that the commits tell
the right story. The final diff should both build and lint. If the LSP complains while in the middle of refactoring it
is safe to ignore those diagnostic issues since it's not important that intermediate state should build or lint.

### Guidance: Moved Files

If a file has been "moved" (even if git doesn't think it has) then there should be a preliminary commit which moves the
file without an accompanying diff. This will let the reviewer understand the changes more easily because the diffs will
be for the same file even though they are different in the final diff.

For example, if cds/service/history/queues/tiered_storage_queue_factory.go was moved to cds/service/history/queues/tiered_storage/factory.go
it should be moved in a preliminary commit, with followup commits handling the diffs of that actual file. If git reported
the move as an actual move instead of a deletion and a creation, then that is not necessary.

### Guidance: What's Too Much?

If a commit is quite large (let's say a thousand changes) it's almost certain that this is too large for someone to
understand if they are reviewing it in commit order. Look for patterns in the diff that belong to different concerns
and business logic. Those are likely separate commits that would make it easier to understand for the reviewer.

### Guidance: Generated Files

If a file is generated from source that has changed (e.g. gomock mocks), then the generated code should be isolated
to a commit following the source that caused it to change. The advice applies for protobuf definitions and the code
that is generated from them.

### Guidance: Commit Message Prefixes

To help the reviewer more clearly understand the nature of the commits, prepend the commits with consistent prefixes
assigned to the nature of the commits. For example, three commits for the aggregator might be prefixed with agg:.

## Workflow

1. Rebuild the commits per the guidance above.
2. Launch a subagent to review the commits in commit order. Instruct the subagent to report
   back on how easy it was to understand the changes by reading each commit in order. 
3. Take the feedback from the subagent and plan out adjustments for improvement.
4. Inform the user with a brief summary of the feedback from the subagent and the plans for improvement.

The user may decide to go ahead with the next round of planned improvements. Wait for the OK from the user before making
those changes. This process may repeat until the user is happy.

## User Context

$ARGUMENTS
