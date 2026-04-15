---
name: code-review
description: >-
  Multi-aspect code review. Delegates to a lead review agent that dispatches
  focused workers for correctness, security, performance, concurrency, error
  handling, readability, and best practice, then consolidates into one verdict.
  Trigger when the user asks to "review this code", "review PR", or similar.
---

# Code Review

Delegate to the `code-review` lead agent.

Pass the user's original request as the prompt so the lead agent knows what to
review: PR URL, branch name, file path, current diff, staged diff, or snippet.

The lead agent dispatches focused aspect workers. Each worker loads only its
own `code-review` aspect guide.
