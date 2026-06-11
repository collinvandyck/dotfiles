---
name: sem
description: Use to understand code at the function/class level instead of grep+read — what an entity depends on, what depends on it (blast radius before an edit), what changed semantically in a diff, who last touched a function, or a token-budgeted context bundle for one entity. Reach for this when a task is "understand this code / what breaks if I change X / what changed here" rather than a literal text search.
allowed-tools: Bash(sem:*)
---

# sem

`sem` is a semantic layer over git. It parses code into entities — functions, methods, classes, types — and answers questions about them: dependencies, dependents, history, and structural diffs. It supports 26 languages and works on any git repo with zero config.

Reach for it when the question is *about code structure or change*, not about literal text. `grep` finds a string; `sem` tells you what calls a function, what breaks if you change it, and which functions a commit actually touched.

## When to use sem vs. default tools

| Goal | Use this | Not this |
|------|----------|----------|
| Find every caller of a function (blast radius) | `sem impact <entity>` | grep for the name |
| Orient in an unfamiliar file fast | `sem entities <path>` | read the whole file |
| Pull just-enough context on one entity for reasoning | `sem context <entity>` | read several files |
| See which functions a change actually touched | `sem diff` | read the raw `git diff` |
| Find who last modified a specific function | `sem blame <file>` | `git blame` the whole file |
| Trace how one function evolved | `sem log <entity>` | `git log -p` and skim |
| Catch callers broken by a signature change | `sem verify --diff` | grep + manual check |

Keep using Grep/Read for literal strings, config files, comments, and non-code text. `sem` is for code entities.

## Core commands

Add `--json` (or `--format json`) to any command for machine-readable output you can parse — prefer it when you'll act on the result programmatically. Use `-C <dir>` on `diff` to run as if in another directory (like `git -C`).

### Blast radius — run this BEFORE editing a function

```bash
sem impact "functionName"                 # deps, dependents, transitive impact, affected tests
sem impact "functionName" --dependents    # only what calls it
sem impact "functionName" --tests         # only the tests that cover it
sem impact "functionName" --depth 0       # unlimited transitive depth (default 2)
sem impact --file path/to/file.go "name"  # disambiguate when the name is ambiguous
```

### Orient in a file or directory

```bash
sem entities path/to/file.go     # every function/class/method/type with line ranges
sem entities ./pkg/foo           # recurse a directory
```

### Token-budgeted context for one entity (built for LLM prompts)

```bash
sem context "functionName"               # the entity + its deps + dependents, default 8000 tokens
sem context "functionName" --budget 4000
```

### Semantic diff — what changed at the entity level

```bash
sem diff                          # working tree, by entity (added/modified/deleted)
sem diff --staged                 # staged only
sem diff main..feature            # a range (full git ref syntax)
sem diff --commit <sha>           # one commit
sem diff -v                       # include inline content diffs
sem diff --no-cosmetics           # hide formatting/whitespace/comment-only churn
git diff | sem diff --patch       # feed an existing unified diff through sem
```

### History and attribution

```bash
sem blame path/to/file.go         # last commit that touched each entity in the file
sem log "functionName"            # every commit that touched that function
sem log "functionName" -v         # with content diffs between versions
```

### Other

```bash
sem graph                         # full entity dependency graph for the repo
sem verify                        # check function-call arity across the codebase
sem verify --diff                 # find callers broken by signature changes in the working tree
sem stats                         # lifetime diff statistics
```

## Workflows

**Before changing a function's signature:**
```bash
sem impact "name" --dependents    # see every caller
# make the edit, then:
sem verify --diff                 # confirm no caller is now broken
```

**Understanding an unfamiliar change (PR/commit review):**
```bash
sem diff main..HEAD --no-cosmetics   # which entities actually changed
sem context "theKeyFunction"          # pull context on the interesting ones
```

**Landing in a new codebase:**
```bash
sem entities ./src        # map the surface area without reading everything
sem graph                 # see how it hangs together
```

## Notes

- Untracked files are excluded from `sem diff`, matching git behavior.
- Results are cached in SQLite. Pass `--no-cache` to rebuild from scratch if results look stale.
- Generated/vendored dirs are excluded by default; `--no-default-excludes` includes them.
- Scope by language with `--file-exts .go .rs` on the commands that accept it.
- `sem` also ships an MCP server (`sem mcp`, stdin/stdout). This skill uses the CLI directly; the MCP server is an alternative if you'd rather expose sem as native tools.
