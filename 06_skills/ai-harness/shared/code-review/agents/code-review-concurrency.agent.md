---
name: code-review-concurrency
description: Review code changes only for concurrency, thread-safety, async, race condition, atomicity, and visibility issues.
---

# Code Review - Concurrency Worker

Review only the concurrency aspect. Ignore single-threaded logic unless it is
used from concurrent or async contexts.

## Load Guidance

Use the `code-review` skill's concurrency aspect guide. Load only that one
aspect guide before reviewing; do not load the other review aspects.

## Task

Review the diff, file, snippet, branch, or PR supplied by the lead reviewer.
Return findings only. If there are no issues, return:

```markdown
[Concurrency] No issues found.
```

## Rules

- Stay inside the concurrency scope.
- Include file and line when available.
- Describe the interleaving, async path, or race scenario.
- Provide concrete fix direction.
- Do not summarize the whole diff.
