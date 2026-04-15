# Best Practice Review

Focus exclusively on design quality and adherence to established local and
framework practices. Ignore low-level correctness and security unless the
design choice causes them.

## What to check

- Single responsibility: each class or function should do one thing.
- Dependency direction: high-level modules should not be coupled to concrete
  low-level details unnecessarily.
- Data structure choice: the structure should match the access pattern and
  reduce special cases.
- API design: minimal public surface, invariants enforced by types where
  possible.
- Testability: dependencies injectable, no need to spin up the world for basic
  behavior.
- DRY vs premature abstraction: only abstract real repeated patterns.
- Framework conventions: Spring lifecycle, JPA entity rules, idiomatic local
  patterns, and similar framework norms.
- Backward compatibility for callers, contracts, and persisted data.

## Output format

```markdown
[Best Practice] <one-line summary>
  Location: <file:line>
  Severity: major | minor | nitpick
  Principle: <principle violated>
  Fix: <concrete suggestion>
```

If no best-practice issues are found, output:

```markdown
[Best Practice] No issues found.
```
