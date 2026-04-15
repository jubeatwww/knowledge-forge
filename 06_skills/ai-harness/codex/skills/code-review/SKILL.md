---
name: code-review
description: Multi-aspect code review covering correctness, security, performance, concurrency, error handling, readability, and best practice. Use when the user asks to review code, review current changes, review a PR, review a branch, or perform a pragmatic review. If the user explicitly asks for parallel, delegated, sub-agent, or multi-agent review, dispatch focused aspect workers; otherwise review locally and load only relevant aspect guides.
---

# Code Review

Perform a direct, technical review focused on real defects and maintainability
risk. Findings come first, sorted by severity, with concrete fixes.

Respond in the same language the user uses.

## Guiding Principles

- Prefer good data structures over special-case logic.
- Treat backward compatibility as a hard constraint unless the user says
  breaking behavior is acceptable.
- Flag real production risks; skip speculative complaints.
- Keep the review technical. Comment on code, never the author.

## Workflow

### 1. Determine the review scope

Resolve what to review from the user's request:

- Current local changes: inspect `git status --short`, `git diff --stat`, and
  `git diff`.
- Staged changes: inspect `git diff --cached --stat` and `git diff --cached`.
- Branch review: compare against the requested base branch, or infer the base
  from the repository workflow if obvious.
- PR review: use available GitHub tooling or `gh pr diff` when authenticated.
- File or snippet review: read only the referenced file or snippet.

When the base is ambiguous, state the assumption. Ask only if the wrong base
would make the review misleading.

### 2. Choose review mode

Default mode is local review by the current Codex agent. In local mode, read
only the `code-review` aspect guides that are relevant to the code under
review. Do not load all seven guides just because they exist.

Use subagents only when the user explicitly asks for parallel, delegated,
sub-agent, or multi-agent review and the active environment permits spawning.

When subagents are allowed, dispatch these focused workers:

- `code-review-correctness`
- `code-review-security`
- `code-review-performance`
- `code-review-concurrency`
- `code-review-error-handling`
- `code-review-readability`
- `code-review-best-practice`

Pass each worker the same review scope and instruct it to load only its own
`code-review` aspect guide. Then deduplicate and judge the consolidated result
yourself.

### 3. Consolidate findings

- Remove exact duplicates.
- Keep distinct issues on the same line if the failure mode differs.
- Sort by severity: fatal, major, minor, nitpick.
- Upgrade or downgrade severity based on actual impact, not the aspect file's
  wording.

Severity guidance:

- `fatal`: likely data loss, security exposure, production outage, or clear
  incorrect behavior in a core flow.
- `major`: real bug or maintainability risk that should block merge.
- `minor`: valid issue that should be fixed but does not block merge alone.
- `nitpick`: small readability or consistency issue.

### 4. Output format

Use this structure:

```markdown
## Findings

[Aspect] Issue summary
  Location: file:line
  Severity: fatal | major | minor | nitpick
  Details: ...
  Fix: ...

## Taste Rating

Good Taste | Mediocre | Garbage

## Direction for Improvement

- ...
```

If there are no actionable issues, say that clearly and mention any residual
risk, such as missing tests or an unverified runtime path.

## Rules

- Lead with findings. Keep summaries secondary.
- Every finding needs a location, severity, evidence, and fix direction.
- Do not invent test results, PR metadata, or production impact.
- Quote only the minimal code needed to prove the issue.
- If the code is acceptable, keep the response short.
