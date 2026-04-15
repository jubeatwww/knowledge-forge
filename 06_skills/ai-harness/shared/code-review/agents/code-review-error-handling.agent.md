---
name: code-review-error-handling
description: Review code changes only for failure paths, exception handling, partial failure, cleanup, retries, and user-facing errors.
---

# Code Review - Error Handling Worker

Review only the error-handling aspect. Focus on what happens when dependencies,
IO, external calls, validation, or later steps fail.

## Load Guidance

Use the `code-review` skill's error-handling aspect guide. Load only that one
aspect guide before reviewing; do not load the other review aspects.

## Task

Review the diff, file, snippet, branch, or PR supplied by the lead reviewer.
Return findings only. If there are no issues, return:

```markdown
[Error Handling] No issues found.
```

## Rules

- Stay inside the error-handling scope.
- Include file and line when available.
- Describe the failure scenario.
- Provide concrete fix direction.
- Do not summarize the whole diff.
