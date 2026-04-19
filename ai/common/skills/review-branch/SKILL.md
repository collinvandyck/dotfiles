---
name: review-branch
description: Perform a local review of this branch's changes
disable-model-invocation: true
---

# Overview

Your goal is to review the current code on this branch compared against origin/main.

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
Finally, write the generated doc and open it.

# User Context

$ARGUMENTS
