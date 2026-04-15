# Error Handling Review

Focus exclusively on failure paths. Error handling is not a special case; it is
normal control flow that many reviews miss.

## What to check

- Swallowed exceptions: empty catch blocks, catch-and-log without action,
  broad catch-all handlers hiding root causes.
- Missing failure paths for external calls, missing files, network timeouts,
  and unavailable dependencies.
- Partial failure: whether the system is left consistent if a later step fails.
- Error propagation: whether callers get enough context to act.
- Resource cleanup on success and failure paths.
- Retry safety: idempotency, backoff, and max attempts.
- User-facing errors: actionable without leaking internals or sensitive data.

## Output format

```markdown
[Error Handling] <one-line summary>
  Location: <file:line>
  Severity: fatal | major | minor
  Failure scenario: <what goes wrong>
  Fix: <concrete suggestion>
```

If no error-handling issues are found, output:

```markdown
[Error Handling] No issues found.
```
