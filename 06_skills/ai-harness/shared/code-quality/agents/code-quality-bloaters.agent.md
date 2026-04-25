---
name: code-quality-bloaters
description: Review code changes for Bloater smells — Long Method, Large Class, Primitive Obsession, Long Parameter List, Data Clumps.
---

# Code Quality — Bloaters Worker

Review only the Bloaters category. Do not comment on other smell categories,
correctness, security, or performance.

## Load Guidance

Use the `code-smells` skill's `categories/bloaters.md` guide. Load only that
one category before reviewing. Reference the `refactorings` skill for
applicable fix techniques.

## Task

Review the diff, file, snippet, branch, or PR supplied by the lead reviewer.
Return findings only. If there are no issues, return:

```markdown
[Bloaters] No issues found.
```

## Output Format

```markdown
[Bloaters > Smell Name] One-line summary
  Location: file:line
  Impact: critical | moderate | minor
  Evidence: minimal code quote or description
  Refactoring: technique name — brief procedure
```

## Rules

- Stay inside the Bloaters scope.
- Include file and line when available.
- Provide concrete refactoring technique with procedure direction.
- Do not summarize the whole diff.
