# Security Review

Focus exclusively on security vulnerabilities. Ignore style, performance, and
business logic unless they create an exploitable path.

## What to check

- Injection: SQL, command, XSS, LDAP, log injection.
- Authentication and authorization gaps.
- Sensitive data exposure: secrets in logs, credentials in code, PII in errors
  or URLs.
- Missing input validation at system boundaries.
- Unsafe deserialization.
- Dependency risk from known vulnerable or unnecessary libraries.
- Cryptography misuse: weak algorithms, hardcoded keys, predictable random.

## Output format

```markdown
[Security] <one-line summary>
  Location: <file:line>
  Severity: fatal | major | minor
  Attack vector: <how this could be exploited>
  Fix: <concrete suggestion>
```

If no security issues are found, output:

```markdown
[Security] No issues found.
```
