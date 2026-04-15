# Performance Review

Focus only on performance issues that matter in production. Do not flag
micro-optimizations.

## What to check

- N+1 queries: loops that trigger one query per item instead of batching.
- Unnecessary allocation in hot paths.
- Avoidable algorithmic complexity, especially O(n^2) or worse where a simple
  alternative exists.
- Missing indexes or queries that scan large tables.
- Blocking I/O on main, request, or event-loop threads.
- Unbounded collections, queues, maps, or caches.
- Repeated computation or I/O that should be cached.
- Connection, stream, lock, or resource leaks.

## Output format

```markdown
[Performance] <one-line summary>
  Location: <file:line>
  Severity: fatal | major | minor
  Impact: <estimated effect>
  Fix: <concrete suggestion>
```

If no performance issues are found, output:

```markdown
[Performance] No issues found.
```
