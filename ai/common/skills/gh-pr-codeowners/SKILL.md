---
description: Given a PR, compute the minimal set of CODEOWNERS groups whose approval satisfies all required review rules for the changed files.
---

# Skill: aistp

Note: `gh` commands talk to GitHub over the network and need keyring credentials, which the default sandbox blocks. Run them outside the sandbox; an auth or network failure there is the sandbox, not a real credential problem, so retry unsandboxed rather than giving up.

Given a PR reference (URL or number):

## Step 1: Gather changed files and CODEOWNERS

```bash
gh pr diff <pr-ref> --name-only
```

Read the repo's CODEOWNERS file (check `.github/CODEOWNERS`, `CODEOWNERS`, then `docs/CODEOWNERS`; the first one found wins).

## Step 2: Match each changed file to its rule

For each changed file, the required reviewers come from the **last** CODEOWNERS pattern that matches it (last match wins, standard CODEOWNERS semantics).

## Step 3: Compute the minimal owner set

Report the minimal set of owner groups whose approval satisfies every matched rule, applying these rules exactly:

- **OR within a line.** When one line lists multiple owners (e.g. `* @temporalio/saas @temporalio/cgs @temporalio/capacity`), that's OR, not AND. One approval from any listed owner satisfies that line. Never treat co-listed owners as each needing their own stamp.
- **Distinct lines stack.** Only separate lines (different path patterns) that match the changed files stack as separate requirements.
- **Child satisfies parent, never the reverse.** A subteam's stamp collapses up into satisfying its parent's rule when the child's approval alone would satisfy the same rule. For example, `@temporalio/cloud-growth`'s stamp covers the default `@temporalio/saas` rule, since cloud-growth is a subteam of saas. But a saas stamp does NOT cover a cloud-growth-specific rule, since not every saas approver is on cloud-growth. The collapse only ever goes child-satisfies-parent.

Return the minimal set of groups, noting which changed paths drive each requirement.
