# Concurrency Review

Focus exclusively on concurrency and thread-safety issues. Ignore
single-threaded logic, style, and performance unless they create concurrency
risk.

## What to check

- Race conditions on shared mutable state.
- Deadlocks from lock ordering, nested locks, or lock-then-block patterns.
- Atomicity violations such as check-then-act without a lock.
- Visibility bugs, especially mutable Java or Kotlin fields read across
  threads without synchronization or `volatile`.
- Thread-unsafe collections used concurrently.
- Lost updates in memory or in the database.
- Starvation, livelock, and unbounded waits.
- Async pitfalls: missing await, unhandled async exceptions, hidden callback
  failures.

## Output format

```markdown
[Concurrency] <one-line summary>
  Location: <file:line>
  Severity: fatal | major | minor
  Scenario: <interleaving or async path that triggers the bug>
  Fix: <concrete suggestion>
```

If no concurrency issues are found, output:

```markdown
[Concurrency] No issues found.
```
