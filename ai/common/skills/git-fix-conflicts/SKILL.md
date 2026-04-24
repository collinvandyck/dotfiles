---
name: git-fix-conflicts
description: There are git conflicts in a merge or rebase and we need to fix them.
allowed-tools: Bash, Read
disable-model-invocation: true
---

# Overview

Your goal is to fix the merge or rebase conflicts. If the user has not given explicit information about the current state, look to see whether or not a merge or rebase is in progress.

For each conflict, you should understand the the current branch code as well as the other branch that is being merged or rebased onto. The merges should be semantically correct. If you're not clear on the intent, ask the user for guidance.

After the fixed have been applied, supply a summary of the changes made and why to the user. This can be brief unless the changes were difficult or nuanced. Add detail where it makes sense.

# User Context

$ARGUMENTS

