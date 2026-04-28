---
title: Trace Call Chain Skill
kind: skill-index
tags:
  - debugging
  - call-chain
  - code-tracing
  - general
---

# Trace Call Chain Skill

General-purpose call chain tracer for any codebase and language.
Discovers all callers and/or callees of a target symbol, validates
each path with an AI harness, and produces a scoped report with
Mermaid diagrams saved to file.

## Files

- [[SKILL]] — agent entry, workflow (6 phases), output contract, rules
- [[discovery]] — search strategy, path object schema, async handling, diagram prompts
- [[harness]] — per-path verification checklist, gap detection, confidence scoring
- [[report-template]] — final report skeleton and Mermaid cheatsheet

## Related

- [[../table-archive-analysis/INDEX|table-archive-analysis]] — similar pattern for DB tables (Sporty-specific)
- [[../requirement-analysis/SKILL|requirement-analysis]] — use before tracing to decide if worth investigating
- [[../../../INDEX]]