---
name: create-detailed-plan
description: Create a thorough, research-backed development plan with milestones and verification steps.
allowed-tools: Bash, Read, Grep, Glob, Agent, WebFetch, Skill(write-generated-doc)
disable-model-invocation: true
argument-hint: "<description of feature, fix, or change>"
---

# Overview

Your goal is to create a detailed, research-backed development plan for the work the user specifies. If the user does not specify, prompt for details.

The plan is written for a developer who is skilled but has zero context on this codebase or problem domain. Everything they need — file paths, code snippets, diagrams, verification steps — goes into the plan.

# Process

Follow these phases in order.

## Phase 1: Clarify

Before doing any research, read the user's request carefully. If anything is ambiguous — scope, constraints, target behavior — ask before proceeding. Don't guess at requirements.

## Phase 2: Research

Explore the codebase before writing a single line of the plan. The goal is to understand the territory so the plan is grounded in reality, not assumptions.

- **Find the affected code.** Grep for relevant types, functions, config. Read the key files. Understand the dependency graph.
- **Study existing patterns.** Look at how similar things were done in this codebase. The plan should follow suit unless there's a good reason not to.
- **Check for related config, docs, or tests.** Dynamic config, feature flags, existing test fixtures, ADRs, README sections — anything that might affect the approach.
- **Identify boundaries.** What modules/packages does this touch? What's the blast radius? Where are the integration points?
- **Explore connected repositories.** Most work here spans multiple repos. Check for cross-cutting concerns:
  - Grep for shared types, interfaces, or proto definitions that callers in other repos depend on
  - Check how other repos consume or interact with the code you're changing (e.g., if you're modifying a service in `saas-temporal`, check how `saas-components` deploys or configures it, or how `saas-control-plane` calls it)
  - Look for coordinated changes — does this require a matching proto update, config change, deployment change, or migration in another repo?
  - Identify ordering constraints — which repo's changes need to land first?

  Connected repos to consider (all under ~/code/temporal/):
  - `saas-temporal` — server + CDS persistence layer
  - `saas-components` — cloud deployment and service configuration
  - `saas-control-plane` — controlplane code and workflow workers
  - `saas-infra-plane` — infrastructure code and workflow workers
  - `saas-proto` — protobuf definitions shared across services
  - `temporal` — open source server
  - `runbooks` — internal documentation

  Not every repo will be relevant every time. Use judgment — but when a change touches service boundaries, RPCs, protos, config, or deployment, check the other side.

Use Grep, Glob, Read, and Agent (Explore) liberally — across repos, not just the current one. Reading code is not optional here — it's the whole point.

## Phase 3: Write the Plan

Structure the plan as described below. 

# Plan Structure

## Header

```markdown
# [Feature/Fix Name] — Development Plan

**Goal:** [One sentence. What does this accomplish?]

**Approach:** [2-4 sentences. High-level strategy and key design decisions.]

**Affected Areas:** [List of packages, modules, or services touched — include other repos if applicable]
```

## Section 1: Walkthrough

A guided, conversational walkthrough of the existing code that the developer needs to understand before starting. This is not a full codebase tour — only the parts relevant to this work.

- Use diagrams (ascii-art in fenced code blocks) for flows, data paths, or component relationships
- Use fenced code blocks for relevant snippets
- Use analogies for complex concepts
- Point out non-obvious behavior, gotchas, or implicit contracts

## Section 2: Milestones

A sequence of incremental milestones that converge on the solution. Each milestone should be a logical, committable chunk of work — small enough to reason about, large enough to be meaningful.

Each milestone follows this format:

```markdown
### Milestone N: [Short Name]

**What:** [1-2 sentences describing what this milestone accomplishes]

**Files:**
- Create: `exact/path/to/new_file.go`
- Modify: `exact/path/to/existing.go` — [brief description of change]
- Test: `exact/path/to/file_test.go`

**Steps:**
1. [Concrete action — not "add validation" but what validation, where, why]
2. [Next action]
3. ...

**Verify:**
- Run: `go test ./path/to/... -run TestName -v`
- Expected: [What passing looks like]
- Manual check: [If applicable — e.g., "query the table and confirm X"]

**Commit:** `feat: add [thing]` or `fix: resolve [issue]`
```

Guidelines for milestones:
- **Exact file paths, always.** No "the handler file" — say `service/frontend/handler.go`.
- **Show the code.** Include code snippets for non-trivial changes. If a function signature matters, write it out.
- **Each milestone has a verification step.** Tests, commands, manual checks — something concrete that proves it works.
- **Follow existing patterns.** If the codebase puts tests in `_test.go` files next to the source, do that. If there's a test helper convention, use it.
- **Order milestones so each one builds on the last.** The codebase should compile and tests should pass after every milestone.
- **For cross-repo changes, call out the repo and ordering.** If milestone 3 requires a proto change in `saas-proto` before the server change in `saas-temporal`, say so explicitly. Each milestone's Files section should include the repo when it's not the current one (e.g., `saas-proto/temporal/api/cloud/...`).

## Section 3: Risks & Gotchas

Things the developer should watch out for:
- Race conditions, edge cases, subtle ordering dependencies
- Areas where the existing code is fragile or non-obvious
- Performance implications
- Migration or backwards-compatibility concerns
- Things that look like they should work but won't (and why)

Be specific. "Be careful with concurrency" is not useful. "The `ShardController` acquires locks in a specific order — see `controller.go:245` — and violating that order will deadlock" is useful.

# Style

- Conversational but precise. Explain the *why* behind decisions.
- Use diagrams and code snippets where they aid clarity.
- Diagrams should be ascii-art inside fenced code blocks.
- Do not use soft breaks in the generated output.
- DRY — if two milestones share context, explain it once and reference it.
- YAGNI — don't plan for things that aren't needed yet.

# Finally

*IMPORTANT* When the plan is complete, invoke the `write-generated-doc` skill to save it and open it.

# User Context

$ARGUMENTS
