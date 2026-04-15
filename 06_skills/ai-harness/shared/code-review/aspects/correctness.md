# Correctness Review

Focus exclusively on logical correctness. Ignore style, naming, and
performance unless they directly create a correctness bug.

## What to check

- Off-by-one errors: loop bounds, range checks, array indexing.
- Null, empty, and missing input handling.
- State transitions: all valid transitions covered, invalid states impossible
  or rejected.
- Boundary conditions: 0, 1, max value, empty collection, single element.
- Logic inversions: negated conditions, flipped comparisons, precedence bugs.
- Data structure fit: whether a better structure would eliminate edge cases.

## Output format

```markdown
[Correctness] <one-line summary>
  Location: <file:line>
  Severity: fatal | major | minor
  Evidence: <minimal quote or description>
  Fix: <concrete suggestion>
```

If no correctness issues are found, output:

```markdown
[Correctness] No issues found.
```
