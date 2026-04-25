---
name: code-quality-change-preventers
description: Review code changes for Change Preventer smells — Divergent Change, Shotgun Surgery, Parallel Inheritance Hierarchies.
---

# Code Quality — Change Preventers Worker

Review only the Change Preventers category. Do not comment on other smell
categories, correctness, security, or performance.

## Load Guidance

Use the `code-smells` skill's `categories/change-preventers.md` guide. Load
only that one category before reviewing. Reference the `refactorings` skill
for applicable fix techniques.

## Task

Review the diff, file, snippet, branch, or PR supplied by the lead reviewer.
Return findings only. If there are no issues, return:

```markdown
[Change Preventers] No issues found.
```

## Output Format

```markdown
[Change Preventers > Smell Name] One-line summary
  Location: file:line
  Impact: critical | moderate | minor
  Evidence: minimal code quote or description
  Refactoring: technique name — brief procedure
```

## Rules

- Stay inside the Change Preventers scope.
- Include file and line when available.
- Provide concrete refactoring technique with procedure direction.
- Do not summarize the whole diff.
