---
name: create-plan
description: Create a development plan for a project or fix.
allowed-tools: Bash, Read, WebFetch
disable-model-invocation: true
---

# Overview

Your goal is to create a detailed project plan for the project that the user will specify.
If the user does not specify, prompt the user for details.
The plan should include these high level sections:

1. Walkthrough: A guided, conversational walkthrough of the existing code. Use diagrams and code snippets where it would
   benefit clarity. Assume the user has limited context unless otherwise specified.

2. Milestones: A set of incremental smaller goals that eventually converge on a solution.

3. Risks: Things that the developer should watch out for. Point out common mistakes or areas that might be tricky.

Before making the plan, ask the user for any clarification you need.
Finally, write the generated doc and open it.

# Details

- Use analogies and visual diagrams when appropriate
- use fenced code blocks to showcase relevant code snippets to increase understanding
- Keep explanations conversational. For complex concepts, use multiple analogies.

# User Context

$ARGUMENTS

