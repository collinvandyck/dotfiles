---
name: track
description: Given a set of tasks by the user, create claude code tasks to track but not immediately start on
disable-model-invocation: true
model: haiku
---

# Overview

The user has supplied some tasks for you to create as claude code tasks. Once the tasks are created, do not
immediately start on them unless the user has asked you to do so.

## Example

    /track get the saas-temporal branch merged against main
    get the ch-deploy branch merged against main
    rework and clean up the saas-temporal commits
    create the saas-temporal draft pr
    clean up the ch-deploy commits and create the ch-deploy draft pr

This should result in five tasks.

## Example

    /track merge origin/main into our branch and create a draft pr

This should result in two tasks.

# User Context

$ARGUMENTS

