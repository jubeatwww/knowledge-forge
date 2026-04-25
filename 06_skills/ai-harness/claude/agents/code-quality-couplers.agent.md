---
name: code-quality-couplers
description: Review code changes for Coupler smells — Feature Envy, Inappropriate Intimacy, Message Chains, Middle Man, Incomplete Library Class.
---

# Code Quality — Couplers Worker

Review only the Couplers category. Do not comment on other smell categories,
correctness, security, or performance.

## Load Guidance

Use the `code-smells` skill's `categories/couplers.md` guide. Load only that
one category before reviewing. Reference the `refactorings` skill for
applicable fix techniques.

## Task

Review the diff, file, snippet, branch, or PR supplied by the lead reviewer.
Return findings only. If there are no issues, return:

```markdown
[Couplers] No issues found.
```

## Output Format

```markdown
[Couplers > Smell Name] One-line summary
  Location: file:line
  Impact: critical | moderate | minor
  Evidence: minimal code quote or description
  Refactoring: technique name — brief procedure
```

## Rules

- Stay inside the Couplers scope.
- Include file and line when available.
- Provide concrete refactoring technique with procedure direction.
- Do not summarize the whole diff.
