# Readability Review

Focus exclusively on readability and maintainability. Ignore correctness,
security, and performance unless the readability issue makes them likely.

## What to check

- Nesting depth above three levels; prefer early returns or extraction.
- Functions too long to understand in one screen.
- Names that describe implementation rather than intent, or cryptic
  abbreviations.
- Dead code: unreachable branches, unused variables, commented-out blocks.
- Magic numbers and strings that should be named constants.
- Consistency with patterns already established in the same file or module.
- Comments that explain what the code already says instead of why it exists.

## Output format

```markdown
[Readability] <one-line summary>
  Location: <file:line>
  Severity: major | minor | nitpick
  Fix: <concrete suggestion>
```

If no readability issues are found, output:

```markdown
[Readability] No issues found.
```
