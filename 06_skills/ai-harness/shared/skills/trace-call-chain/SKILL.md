---
name: trace-call-chain
description: >-
  Trace all call chains for a given function, method, class, or endpoint in
  any codebase. Use when debugging bugs, mapping data flow, or investigating
  unexpected behavior. User provides the target symbol and scope; the skill
  discovers all callers and/or callees, dispatches subagents to trace each
  path in detail, validates with an AI harness, and saves a scoped report with
  Mermaid diagrams to file.
---

# Trace Call Chain

Map every path that leads into or out of a target symbol — function, method,
class, endpoint, event handler — to understand how it is used and debug
unexpected behavior.

## Scope Guardrails

- Works with any language or codebase. No Sporty or DB-specific assumptions.
- Scope is provided by the user (directory glob, file pattern, module name).
  If scope is missing, ask before proceeding.
- If the target symbol is ambiguous, list the candidates and ask the user to
  confirm before tracing.
- If the output path is not provided, ask before writing the report.

## Inputs

Required:
- **target** — the symbol to trace (function, method, class, endpoint, event name)

Optional:
- **scope** — file or directory patterns to search (default: current repo root)
- **direction** — `callers` (who calls this?), `callees` (what does this call?),
  or `both` (default: `callers`)
- **depth** — max chain depth to trace (default: unlimited until entry point)
- **output path** — where to write the final report

If direction is not specified, default to `callers` and state the assumption.

## Workflow

### Phase 1 — Gather Context

Confirm target, scope, direction, and output path with the user before
proceeding. Restate understood parameters in one short block.

Reference: `discovery.md` §1

### Phase 2 — Shallow Discovery (Big Picture)

Search the codebase within scope to find every file that directly references
the target symbol. Build a top-level caller/callee map without tracing deep
yet. Group by layer if layer names are detectable (controller/service/handler/
repository/consumer/util/test).

State: how many direct references found, in how many files.

Reference: `discovery.md` §2

### Phase 3 — Deep Trace via Subagents

Once the shallow map is ready, fan out one subagent per caller cluster (or per
direct caller for small targets). Each subagent traces one caller chain upward
to its entry point (or downward to the leaf for callees). Each subagent returns
a normalized path object.

If the host policy requires explicit user approval before delegation, obtain it
first. If delegation is unavailable, trace all paths in the main thread.

Launch all subagents in a single batch. Do not wait between spawns.

Reference: `discovery.md` §3

### Phase 4 — AI Harness Validation

After collecting all path objects, verify each one:
- Every link in the chain is confirmed by code evidence (file:line or snippet).
- No link is inferred purely from naming — grep or read to confirm.
- Check for discovered-but-untraced callers (gaps in coverage).
- Check for logical inconsistencies (impossible call directions, duplicate paths).
- Score each path's confidence: high / medium / low.

Flag unresolved gaps explicitly. If a gap is critical for the user's debug goal,
stop and trace it before proceeding.

Reference: `harness.md`

### Phase 5 — Diagram Generation

After all paths are validated and finalized, generate diagrams. Fan out one
subagent per diagram (overview + one per path) in a single batch.

Diagrams must stay human-readable:
- Overview: max 2–3 levels deep; collapse deeper subtrees into ellipsis nodes.
- Per-path: full chain, but split into Part 1 / Part 2 if >7 nodes.

Reference: `discovery.md` §4

### Phase 6 — Report Assembly and File Output

Assemble the final markdown report using the template structure. Write to the
confirmed output path.

Reference: `report-template.md`

## Output Contract

The final report must contain:
- Confirmed parameters block (target, scope, direction, date)
- Summary (total paths, depth range, async paths, confidence distribution)
- Harness validation summary (gaps, anomalies, unresolved items)
- One overview Mermaid diagram (shallow, ≤3 levels)
- Per-path detail section: one Mermaid + one description table per path
- Debugging recommendations based on the discovered structure
- File written to the confirmed output path

## Rules

- Separate confirmed evidence from inference. Every link must cite file:line.
- Never fabricate a call chain. If a link cannot be confirmed, mark it `[inferred]`
  and flag it in the harness section.
- Keep each Mermaid chart small enough to read without scrolling. Split rather
  than compress.
- Use `flowchart LR` for caller paths (entry → target), `flowchart TD` for
  callee paths (target → leaf).
- For async/event-driven paths, mark the async boundary explicitly in the diagram.
- Conditional calls must be marked as conditional in the path object and diagram.
- Summarize boring repetitive paths (e.g., ten similar test callers) compactly.
  Spend detail on paths relevant to the debug goal.
- The harness validation section is mandatory. Do not skip it even if all paths
  have high confidence.
- Respond in the same language the user is writing in.