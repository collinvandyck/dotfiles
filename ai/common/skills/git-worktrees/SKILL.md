---
name: git-worktrees
description: Use this skill when creating a git worktree or creating a draft pr.
---

# Conditions

If the user asks you to create a worktree for a project in `~/code/temporal/`, you will want to use this skill.
If the user has asked you to create a draft PR for work that has not yet been started, you will want to use this skill to create a worktree for that draft PR.
If you are starting work and you're not on a worktree, and the user has not asked you to create a worktree, ask them if you should create a worktree first.

# Overview

The worktrees in ~/code/temporal are created as siblings. For example, `~/code/temporal/temporal` is the root project (OSS) and the worktrees live alongside it. In this case, `~/code/temporal/temporal-cds-123-feature-slug` would be a worktree of `~/code/temporal/temporal`, as it has the root as a prefix.

When you create a new worktree, prefer the format `$project-$suffix`, where $suffix is the ticket name (if present) along with a slug that is a short identifier for the work being done.

Worktrees created should also have a branch of the form `collin/$suffix`. For example, `collin/cds-123-feature-slug`. The branch's base should be the latest fetched origin/main unless otherwise specified.

