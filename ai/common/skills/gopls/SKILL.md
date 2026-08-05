---
name: gopls
description: Use when a question about Go code is about structure rather than text — who calls this function, what breaks if I change this signature, what shape is this interface or struct, what's in this unfamiliar .go file. Also use when the alternative is reading whole .go files to find out what's in them, or grepping for a symbol name to find its callers. Use before editing too — changing a Go signature or interface method, or calling an unfamiliar API, starts with LSP, not with the edit.
allowed-tools: LSP, Bash(grep:*), Bash(awk:*)
---

# gopls

## Overview

gopls has already type-checked the repo. Reading a `.go` file to learn what's in it, or grepping a symbol name to find its callers, pays tokens for what the type checker hands over far cheaper — and grep gets interface dispatch wrong.

Answer structure questions with LSP. Read source only once you know which lines you need.

Not for: literal strings, config, comments, non-Go files (use Grep); what a commit changed (use `sem diff --no-cosmetics`).

## Quick reference

| Question | Operation | Typical cost |
|---|---|---|
| What's in this file? | `documentSymbol` | ~1.2k for a 600-line file |
| What is this type? What's its contract? | `hover` | ~450 |
| Who calls this concrete function? | `findReferences` | ~60 |
| Who calls this through an interface? | two-hop, below | ~100 |
| What does this call? | `outgoingCalls` | ~100 |
| Where is this defined? | `goToDefinition` | ~30 |
| Find a symbol by name across the repo | `workspaceSymbol` | **~4.5k, caps at 100** |

`documentSymbol` returns every type, field, and method **with full signatures**. `hover` on a type returns the declaration *plus* its doc comment — often where the real semantics are written down.

## Position addressing

All operations except `workspaceSymbol` need `line` and `character`, both 1-based. Get them with grep + awk:

```bash
grep -n "func (s \*Shard) AssertOwnership" cds/shard/shard.go   # -> 275
awk 'NR==275 {print index($0,"AssertOwnership")}' cds/shard/shard.go   # -> 18
```

Two cheap Bash calls beat one 4.5k `workspaceSymbol`.

## True callers in interface-heavy Go

`findReferences` on a concrete method that satisfies an interface returns **only the declaration**. That's correct — nothing names the concrete method; calls dispatch through the interface. Go up, then look down:

1. `goToImplementation` on the concrete method → the interface method it satisfies
2. `findReferences` on *that* → every dispatch site

Skipping step 1 and concluding "no callers" is the likeliest way to be wrong about blast radius. Grep is no safer: real dispatch sites read `p.ExecutionStore.GetWorkflowExecution(_ctx_, _request_)` and `mc.callee.GetWorkflowExecution(mc.Arg0, mc.Arg1)`.

Watch the receiver type on hits — `executionManagerImpl` and `ExecutionStoreWrapper` implement different interfaces at different layers. Grep conflates them; LSP doesn't.

## Common mistakes

| Mistake | Fix |
|---|---|
| `Read` on a `.go` file to see what's in it | `documentSymbol` |
| `workspaceSymbol` to find a line number | `grep -n` for the declaration |
| Grep for a method name to find callers | two-hop; grep misses proxy and wrapper dispatch |
| "findReferences returned 1 hit, so nothing calls it" | It satisfies an interface. Two-hop. |
| Trusting `sem impact --dependents` as a blast radius | It misses interface dispatch. Use LSP. |
| 0-based column from an editor | LSP here is 1-based on both axes |

## Notes

- First call on a large repo pays gopls index latency; tokens are unaffected.
- Calls may append a `<new-diagnostics>` block. While orienting, it's lint hints in unrelated files — ignore. Right after editing a file, read the entries in that file; they're the fastest signal the edit broke something. There's no diagnostics operation, so this block is the only one you get — `go build` and `go vet` are still how you confirm.
- Module-cache paths under `~/go/pkg/mod` resolve fine, so dependencies are navigable too.

Measured: a Go mechanism question answered by reading 27 whole files cost ~143k tokens. The same orientation via `documentSymbol` + `hover` + the two-hop cost ~3.3k — and the `hover` doc comment stated the answer outright.
