---
name: code-quality-review
description: >-
  Copilot wrapper for shared code-smell-based quality review. Dispatches focused
  category workers only when the user explicitly asks for parallel, delegated,
  sub-agent, or multi-agent review; otherwise reviews locally using the
  code-smells and refactorings skills.
---

# Code Quality Review - Copilot Wrapper

Use the `code-quality` shared `lead-reviewer` reference as the lead review
procedure.

Copilot execution mode:

- Dispatch the 5 focused category workers only when the user explicitly asks
  for parallel, delegated, sub-agent, or multi-agent review.
- Otherwise review locally using the code-smells and refactorings skills.
- Consolidate findings through the shared lead review procedure.
