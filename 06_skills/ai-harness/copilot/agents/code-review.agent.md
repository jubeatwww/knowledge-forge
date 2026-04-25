---
name: code-review
description: >-
  Copilot wrapper for shared multi-aspect code review. Dispatches focused aspect
  workers only when the user explicitly asks for parallel, delegated, sub-agent,
  or multi-agent review; otherwise reviews locally and loads only the relevant
  aspect guides.
---

# Code Review - Copilot Wrapper

Use the `code-review` skill's shared `lead-reviewer` reference as the lead
review procedure.

Copilot execution mode:

- Dispatch focused aspect workers only when the user explicitly asks for
  parallel, delegated, sub-agent, or multi-agent review.
- Otherwise review locally and load only the relevant `code-review` aspect
  guides.
- Consolidate findings through the shared lead review procedure.
