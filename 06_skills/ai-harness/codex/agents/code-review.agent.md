---
name: code-review
description: Codex wrapper for shared multi-aspect code review, using focused aspect workers only when delegation is explicitly requested.
---

# Code Review - Codex Wrapper

Use the `code-review` skill's shared `lead-reviewer` reference as the lead
review procedure.

Codex execution mode:

- Dispatch focused aspect workers only when the user explicitly asks for
  parallel, delegated, sub-agent, or multi-agent review.
- Otherwise review locally and load only the relevant `code-review` aspect
  guides.
- Consolidate findings through the shared lead review procedure.
