---
name: code-walkthrough
description: Generate a local walkthrough of the code
allowed-tools: Bash, Read, WebFetch
disable-model-invocation: true
---

# Overview

Your goal is to direct the reader through the specified code. If no parts of the code were specified ask the user to
clarify. The context is that the user is not familiar with this area of the code and would like a guided, conversational,
but professional, walkthrough of the code.

Finally, write the generated doc and open it.

# Details

- Use analogies and visual diagrams when appropriate
- diagrams should be ascii-art inside of fenced code blocks
- use fenced code blocks to showcase relevant code snippets to increase understanding
- The walkthrough should be step-by-step
- Point out common mistakes or areas that may be tricky
- Keep explanations conversational. For complex concepts, use multiple analogies.
- Do not use soft breaks in the generated output.

If you need additional information from the user, ask before generating the walkthrough.

# User Context

$ARGUMENTS

