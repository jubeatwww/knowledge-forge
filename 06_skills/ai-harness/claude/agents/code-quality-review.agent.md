---
name: code-quality-review
description: >-
  Claude wrapper for shared code-smell-based quality review. Dispatches focused
  category workers by default and consolidates their findings through the shared
  lead reviewer procedure.
model: opus
---

# Code Quality Review - Claude Wrapper

Use the `code-quality` shared `lead-reviewer` reference as the lead review
procedure.

Claude execution mode:

- Dispatch the 5 focused category workers in parallel by default.
- Consolidate findings through the shared lead review procedure.
