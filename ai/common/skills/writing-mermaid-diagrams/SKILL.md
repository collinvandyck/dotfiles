---
name: writing-mermaid-diagrams
description: Use when authoring or editing mermaid diagrams (especially sequence diagrams) to avoid parser-breaking characters in note and label text.
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

- Line breaks inside a note or label: use `<br/>`, not a literal newline.
- Always fence the diagram with a ```` ```mermaid ```` code block so it renders.
