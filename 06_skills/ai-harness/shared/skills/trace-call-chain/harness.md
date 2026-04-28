# AI Harness Validation Protocol

After collecting all path objects from subagents (or local tracing), run
this validation protocol before generating diagrams or writing the report.
The goal is to catch hallucinated links, missing paths, and logical errors
before they mislead debugging.

---

## Per-Path Verification Checklist

For each path object, verify:

### V1 — Link Existence
Every edge `A → B` in the call chain must be confirmed by code evidence.
Acceptable evidence:
- Read the source file and found the actual call site (file:line)
- `rg` output showing the symbol name at the call site
- Not acceptable: "likely because the name suggests it"

If a link cannot be confirmed, mark it `[inferred]` and demote confidence to
`low`. Flag in the harness summary.

### V2 — Direction Correctness
Confirm the direction of each call is correct:
- For `callers`: chain should flow Entry → ... → Target (target is called by entry)
- For `callees`: chain should flow Target → ... → Leaf (target calls down to leaf)

A reversed link (B says it calls A, but actually A calls B) is a critical error.
Flag any reversal immediately.

### V3 — Chain Completeness
Check for missing intermediate steps:
- Does Entry actually call the next node directly, or is there a missing hop?
- If a file was found in §2 but its caller was never traced, it is a gap.

List all gaps discovered in §2 that were not resolved in §3.

### V4 — Conditional Branch Coverage
If a call is conditional, confirm:
- The condition was captured in `condition_hint`
- The path is labeled as conditional in the path object
- No path incorrectly treats a conditional call as always-executed

### V5 — Async Boundary Accuracy
If the path crosses an async boundary, confirm:
- The producer side is correctly identified
- The consumer side is correctly identified or marked out-of-scope
- The async mechanism (MQ, event, thread) is correctly named

### V6 — Side Effect Completeness
If the chain modifies other resources (writes to DB, emits events, updates
other state), confirm those side effects are captured.
Missing side effects are common sources of bugs.

---

## Gap Detection Protocol

Run after per-path verification:

1. Collect all files that appeared in §2 (shallow discovery).
2. For each file, check whether it appears in at least one traced path object.
3. Files in §2 but not in any path object are **untraced gaps**.

For each untraced gap:
- Is it a test? → Acceptable to skip; note in summary as "test callers skipped".
- Is it in scope? → Must trace. Add a new path object or delegate to a subagent.
- Is it out of scope? → Note as "out-of-scope reference".

If critical untraced gaps remain, stop Phase 5 (diagrams) and resolve them
first. Ask the user if the gap affects their debug goal.

---

## Confidence Scoring

Assign final confidence to each path:

| Confidence | Condition                                              |
|------------|--------------------------------------------------------|
| `high`     | Every link confirmed by reading the actual source file |
| `medium`   | Some links confirmed by grep only (not full file read) |
| `low`      | One or more links are inferred from names or context   |

Promote `medium` to `high` only after reading the file and confirming the link.
Never promote `low` without finding code evidence.

---

## Harness Summary Block

Output a summary at the end of Phase 4:

```
Harness Validation Summary
──────────────────────────
Paths verified:   N / N
  high confidence: N
  medium:          N
  low:             N

Gaps found:       N
  resolved:       N
  unresolved:     N (list them)

Anomalies:        N
  (list: reversed direction, conditional unmarked, missing side effects, etc.)

Proceed to diagrams: YES / NO (if NO — describe what must be resolved first)
```

If `Proceed: NO`, stop and either resolve the gaps yourself or present them to
the user and ask which paths to prioritize.

---

## Iterative Resolution

If gaps or anomalies are found, run one more tracing iteration before
proceeding:
1. Trace the unresolved gaps (subagent or local).
2. Re-run V1–V6 on the new path objects.
3. Re-score confidence.
4. Re-emit the harness summary.

Repeat until all paths are at least `medium` confidence and no critical gaps
remain, or until the user explicitly says to stop and proceed with what is known.