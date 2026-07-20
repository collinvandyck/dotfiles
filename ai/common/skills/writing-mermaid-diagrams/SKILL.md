---
name: writing-mermaid-diagrams
description: Use BEFORE authoring or editing ANY mermaid diagram (flowchart/graph, sequence, class, state, ER, gantt) in markdown, notes, or docs. Covers syntax that renders wrong or breaks the parser — line breaks in node and edge labels (use <br/>, not backslash-n), and quotes, brackets, pipes, and other special characters in label and note text. Consult it before writing the first diagram line, not after it renders wrong.
---

# Writing Mermaid Diagrams

Guidance for writing mermaid diagrams that parse cleanly the first time. Always fence the block as ```` ```mermaid ````.

## The note/label gotcha (the big one)

Inside the text of a sequence-diagram note (`Note over ...:` / `Note right of ...:`) or a label, two characters silently break the parser:

- A semicolon `;` is treated as a statement separator. The note gets split mid-line and the remainder fails to parse (you'll see something like `Expecting 'TXT', got 'NEWLINE'`). Use a comma or period instead.
- A literal `->` is parsed as an arrow token and breaks the note. When you mean "becomes" or "leads to" inside note text, use the unicode arrow `→` instead.

This applies ONLY to text inside notes and labels. The real message arrows between participants — `->>`, `-->>`, `->`, `-->` used as actual connections — are completely fine. Do not "fix" those; leave them alone.

Incorrect (breaks):
```
Note over Tree: act gone; pointer -> S3, data lost
```
Correct:
```
Note over Tree: act gone, pointer → S3, data lost
```

## Other common pitfalls

- Line breaks inside a node or edge label: use the `<br/>` (or `<br>`) HTML tag, not a `\n` escape. Many renderers (GitHub, Obsidian) show a literal `\n` inside a quoted label as the two characters backslash-n rather than a newline; `<br/>` is the portable way to force the break.
- Always fence the diagram with a ```` ```mermaid ```` code block so it renders.

Incorrect (renders `\n` literally):
```
A["line one\nline two"]
```
Correct:
```
A["line one<br/>line two"]
```
