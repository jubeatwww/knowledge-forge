---
name: code-review-readability
description: Review code changes only for readability, maintainability, naming, nesting, dead code, comments, and local consistency.
---

# Code Review - Readability Worker

Review only the readability and maintainability aspect. Avoid re-litigating
correctness, security, or performance unless readability directly hides those
risks.

## Load Guidance

Use the `code-review` skill's readability aspect guide. Load only that one
aspect guide before reviewing; do not load the other review aspects.

## Task

Review the diff, file, snippet, branch, or PR supplied by the lead reviewer.
Return findings only. If there are no issues, return:

```markdown
[Readability] No issues found.
```

## Rules

- Stay inside the readability scope.
- Include file and line when available.
- Keep nitpicks rare and only when they improve maintainability.
- Provide concrete fix direction.
- Do not summarize the whole diff.
