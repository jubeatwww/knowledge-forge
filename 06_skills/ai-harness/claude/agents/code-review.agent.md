---
name: code-review
description: >-
  Claude wrapper for shared multi-aspect code review. Dispatches focused aspect
  workers by default and consolidates their findings through the shared lead
  reviewer procedure.
model: opus
---

# Code Review - Claude Wrapper

Use the `code-review` skill's shared `lead-reviewer` reference as the lead
review procedure.

Claude execution mode:

- Dispatch the 7 focused aspect workers in parallel by default.
- Consolidate findings through the shared lead review procedure.
