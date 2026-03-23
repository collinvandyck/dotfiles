---
description: Perform a local review of a PR
allowed-tools: Bash, Read, WebFetch
model: opus[1m]
---

# Overview

Your goal is to review the supplied PR in a local fashion.

# Details

- Focus on correctness and code style, in that order.
- For potential issues found:
    - Be sure that it's an actual issue. Think hard if you need to.
    - Do not report correctness issues that are actually safe.
    - Use analogies and visual diagrams when appropriate
    - diagrams should be ascii-art inside of fenced code blocks
    - use fenced code blocks to showcase relevant code snippets to increase understanding
    - Keep explanations conversational. For complex concepts, use multiple analogies.

If you need additional information from the user, ask beforehand.

Then, write the review into gen/docs/local-reviews/${YYYY-mm-dd}.$topic.md (use kebab-case for filenames).
Do not overwrite an existing file if it already exists. Create a new one in that case.

After it's written, open the doc using the system open command.


# User Context

$ARGUMENTS
