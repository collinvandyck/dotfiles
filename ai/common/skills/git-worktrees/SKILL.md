---
name: git-worktrees
description: Use this skill when creating a git worktree or creating a draft pr. Applies to any repository, including ones reached through an installed or managed checkout outside ~/code/temporal (e.g. ~/.cloud-tools, or a path resolved from a binary via `which`).
---

# Conditions

If the user asks you to create a worktree for any git repository, you will want to use this skill.
If the user has asked you to create a draft PR for work that has not yet been started, you will want to use this skill to create a worktree for that draft PR.
If you are starting work and you're not on a worktree, and the user has not asked you to create a worktree, ask them if you should create a worktree first.

Where the repository sits does not change any of this. A repo you found by resolving a binary (`which ct` -> `~/.cloud-tools/src/main/...`), an omni- or mise-managed checkout, or any other clone outside `~/code/temporal` still follows these conventions -- start by finding the root project.

# Find the root project

Worktrees hang off the canonical clone in `~/code/temporal`, not off whichever copy of the repo you happened to open. Before creating anything:

1. Get the remote of the repo you're in: `git remote get-url origin`.
2. If that repo isn't under `~/code/temporal`, look for a clone there with the same remote. The directory name usually matches the repo name, so `temporalio/cloud-tools` is `~/code/temporal/cloud-tools`. That clone is the root project.
3. Run `git worktree list` in the root project. Any existing worktrees show you the naming already in use.
4. If no clone exists under `~/code/temporal`, stop and ask. Don't hang a worktree off a managed checkout.

Managed checkouts -- `~/.cloud-tools` (omni), module caches, anything a tool installed and updates on its own -- are runtime copies. Read them freely, but don't do work in them.

# Overview

The worktrees in ~/code/temporal are created as siblings. For example, `~/code/temporal/temporal` is the root project (OSS) and the worktrees live alongside it. In this case, `~/code/temporal/temporal-cds-123-feature-slug` would be a worktree of `~/code/temporal/temporal`, as it has the root as a prefix.

When you create a new worktree, prefer the format `$project-$suffix`, where $suffix is the ticket name (if present) along with a slug that is a short identifier for the work being done.

`$project` is the root project's directory name, not a directory inside it. A file at `~/code/temporal/cloud-tools/src/main/cell/suppress-alerts.sh` belongs to the `cloud-tools` project, so the worktree is `cloud-tools-$suffix` -- not `src-$suffix`.

Worktrees created should also have a branch of the form `collin/$suffix`. For example, `collin/cds-123-feature-slug`. The branch's base should be the latest fetched origin/main unless otherwise specified.

# Footguns

The worktree must be a sibling of the root project, never a directory inside it. `git worktree add` will happily create one nested in the main working tree, where it then shows up as untracked cruft in `git status`. If you get the path wrong, `git worktree move` fixes it.

After creating the worktree, run `git worktree list` from the root project and confirm the new path sits beside it and is registered to the root project. Registration follows the repo you ran `git worktree add` from, so a worktree created from the wrong clone stays attached to that clone even after you move the directory -- recreate it from the root project instead.
