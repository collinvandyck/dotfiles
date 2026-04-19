---
name: root-cause-hunt
description: Use when investigating which code change caused a reported bug,
  regression, or incident — reading a diff, PR, or commit against a symptom
  report to locate the root cause. Triggers on "find where the bug is", "is
  this PR the cause", "why did this regress", revert/incident investigations,
  or any "here's a symptom + a suspect change, find the error" task.
---

# Root-Cause Hunt

You're matching a symptom to a code change. This skill exists to prevent one
specific failure: finding the real bug, judging it "harmless," and chasing a
more interesting theory instead.

## 1. Pin the symptom as hard constraints (before reading code)
Write down the report's *specific* facts: exact counts, sizes, boundaries,
timing — "exactly 100 stuck", "page size 100", "everything after ID 314".
These are constraints any explanation MUST reproduce. A theory that can't
produce the exact number is wrong. Don't round "exactly 100" to "about 100" —
treat the mismatch as disproof.

## 2. List every behavior change as a suspect
Enumerate each behavioral delta in the diff — including signature swaps,
refactors, and "mechanical" changes. The headline feature is one suspect, not
the default answer. Boring rewrites hide bugs precisely because they get skimmed.

## 3. Don't close a suspect on a local judgment
"That's harmless / not the bug" is a flag, not a verdict. Before parking a suspect:
- Test it at boundary inputs: 0, 1, N, N+1, empty, full.
- Trace its output across call sites to the *consumer*. Harm depends on how the
  result is used — one extra item is harmless unless the consumer advances a
  cursor past it.
Keep dismissed suspects in a visible "parked" list with the reason. Don't delete.

## 4. Re-open parked suspects when your model changes
Every time you learn something new — especially how a consumer behaves — re-scan
the parked list. The suspect you dismissed under partial understanding is where
these bugs live.

## 5. Repro beats argument; a clean repro is a signal
Try to reproduce the fingerprint. A repro that comes out clean ("all tasks
delivered") is evidence *against* your current theory — switch theories, don't
patch the scenario. Work backward from the symptom, not forward from the most
interesting mechanism.
